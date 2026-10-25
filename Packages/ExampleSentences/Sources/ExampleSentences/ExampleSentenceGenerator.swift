//
//  ExampleSentenceGenerator.swift
//  ExampleSentences
//

import Foundation
import FoundationModels

/// One generated example sentence.
public struct ExampleSentence: Sendable, Hashable, Identifiable {
    public let id = UUID()
    public let chinese: String
    public let english: String
    /// Whether the sentence contains the target word. Sentences that don't are
    /// only kept when no attempt produced one that does, so they can be inspected.
    public let containsTarget: Bool
    /// The meaning the sense check thinks the word has in this sentence,
    /// or `nil` when it wasn't checked.
    public var judgedSense: Int? = nil

    /// The sense check agreed the word is used in `sense`.
    public func isVerified(for sense: WordSense) -> Bool {
        containsTarget && judgedSense == sense.number
    }
}

/// The sentences generated for one sense of a word.
public struct SenseExamples: Sendable, Hashable, Identifiable {
    public let sense: WordSense
    public let sentences: [ExampleSentence]
    /// How many model calls it took.
    public let attempts: Int
    /// Set when the model could not produce anything for this sense.
    public let failure: String?

    public var id: Int { sense.id }

    /// At least one sentence uses the target word.
    public var isCovered: Bool {
        sentences.contains(where: \.containsTarget)
    }

    /// At least one sentence passed the sense check. The check is a hint, not a
    /// verdict: it often misreads compounds and near-synonymous senses.
    public var isVerified: Bool {
        sentences.contains { $0.isVerified(for: sense) }
    }
}

/// Example sentences for every sense of a word.
public struct ExampleSentenceResult: Sendable, Hashable {
    public let word: TargetWord
    public let senses: [SenseExamples]

    /// Every sense has at least one sentence that uses the target word.
    public var coversEverySense: Bool {
        senses.allSatisfy(\.isCovered)
    }

    /// A plain-text summary for logs, the command line tool and tests.
    public var report: String {
        var title = "\(word.characters) (\(word.pinyin)) — \(senses.filter(\.isCovered).count)/\(senses.count) senses covered"
        if senses.contains(where: { $0.sentences.contains { $0.judgedSense != nil } }) {
            title += ", \(senses.filter(\.isVerified).count) passed the sense check"
        }
        var lines = [title]
        for examples in senses {
            let mark = examples.isVerified ? "✓" : examples.isCovered ? "?" : "✗"
            lines.append("  \(mark) \(examples.sense.number). \(examples.sense.definition)")
            if let failure = examples.failure {
                lines.append("      ! \(failure)")
            }
            for sentence in examples.sentences {
                var flag = sentence.containsTarget ? "" : "  [missing \(word.characters)]"
                if let judged = sentence.judgedSense, judged != examples.sense.number {
                    flag += "  [sense check: meaning \(judged)]"
                }
                lines.append("      \(sentence.chinese)\(flag)")
                lines.append("      \(sentence.english)")
            }
        }
        if !word.notes.isEmpty {
            lines.append("  Skipped notes: \(word.notes.joined(separator: " | "))")
        }
        return lines.joined(separator: "\n")
    }
}

/// Sentences the model wrote for a word without being asked for particular senses.
public struct FreeExamples: Sendable, Hashable {
    public let word: TargetWord
    /// `judgedSense` is the meaning the model said each sentence uses.
    public let sentences: [ExampleSentence]
    public let failure: String?

    /// The sense numbers the sentences were labelled with, in order.
    public var sensesUsed: [Int] {
        Array(Set(sentences.compactMap(\.judgedSense))).sorted()
    }

    public var report: String {
        var lines = ["\(word.characters) (\(word.pinyin)) — free mode, meanings used: \(sensesUsed.map(String.init).joined(separator: ", "))"]
        if let failure {
            lines.append("  ! \(failure)")
        }
        for sentence in sentences {
            let meaning = sentence.judgedSense.flatMap { number in word.senses.first { $0.number == number } }
            let flag = sentence.containsTarget ? "" : "  [missing \(word.characters)]"
            lines.append("  \(sentence.chinese)\(flag)")
            lines.append("  \(sentence.english)")
            lines.append("    meaning \(meaning.map { "\($0.number). \($0.definition)" } ?? "?")")
        }
        return lines.joined(separator: "\n")
    }
}

/// Writes example sentences for a word with Apple's on-device foundation model,
/// one request per sense so every sense is covered.
public struct ExampleSentenceGenerator: Sendable {
    /// How many sentences to keep for each sense.
    public var sentencesPerSense: Int
    /// Model calls per sense before giving up on getting a sentence that uses the word.
    public var maxAttemptsPerSense: Int
    public var temperature: Double
    /// Ask the model, in a separate call, which meaning each sentence uses,
    /// and list sentences it agrees with first. Mismatches are flagged, not dropped.
    public var checksSense: Bool

    public init(
        sentencesPerSense: Int = 2,
        maxAttemptsPerSense: Int = 3,
        temperature: Double = 0.7,
        checksSense: Bool = true
    ) {
        self.sentencesPerSense = sentencesPerSense
        self.maxAttemptsPerSense = maxAttemptsPerSense
        self.temperature = temperature
        self.checksSense = checksSense
    }

    // MARK: Availability

    public static var isModelAvailable: Bool {
        SystemLanguageModel.default.isAvailable
    }

    /// `nil` when the model is ready, otherwise why it can't be used.
    public static var unavailableReason: String? {
        switch SystemLanguageModel.default.availability {
        case .available:
            return nil
        case .unavailable(let reason):
            return "Apple Intelligence model unavailable: \(reason)"
        }
    }

    // MARK: Generation

    /// Writes a few sentences in one model call, letting the model pick the
    /// meanings (usually the most common ones). Each sentence is labelled with
    /// the meaning the model says it used, for information only.
    public func freeExamples(for word: TargetWord) async -> FreeExamples {
        do {
            let session = LanguageModelSession(instructions: Self.instructions(for: word.script))
            let response = try await session.respond(
                to: Self.freePrompt(for: word),
                generating: GeneratedLabelledSentences.self,
                options: GenerationOptions(temperature: temperature)
            )
            var seen = Set<String>()
            let sentences = response.content.sentences.compactMap { item -> ExampleSentence? in
                let chinese = Self.clean(item.chinese)
                guard !chinese.isEmpty, seen.insert(chinese).inserted else { return nil }
                return ExampleSentence(
                    chinese: chinese,
                    english: Self.clean(item.english),
                    containsTarget: word.isUsed(in: chinese),
                    judgedSense: word.senses.indices.contains(item.meaningNumber - 1) ? item.meaningNumber : nil
                )
            }
            return FreeExamples(word: word, sentences: sentences, failure: nil)
        } catch {
            return FreeExamples(word: word, sentences: [], failure: Self.describe(error))
        }
    }

    /// Generates sentences for every sense of `word`.
    public func generate(for word: TargetWord) async -> ExampleSentenceResult {
        var senses: [SenseExamples] = []
        for sense in word.senses {
            senses.append(await examples(for: sense, of: word))
        }
        return ExampleSentenceResult(word: word, senses: senses)
    }

    /// Generates sentences for one sense, retrying while too few sentences use the word.
    public func examples(for sense: WordSense, of word: TargetWord) async -> SenseExamples {
        var kept: [ExampleSentence] = []
        var rejected: [ExampleSentence] = []
        var failure: String?
        var attempts = 0

        while kept.count < sentencesPerSense, attempts < maxAttemptsPerSense {
            attempts += 1
            do {
                let generated = try await requestSentences(for: sense, of: word)
                failure = nil
                for item in generated.sentences {
                    let chinese = Self.clean(item.chinese)
                    guard !chinese.isEmpty,
                          !kept.contains(where: { $0.chinese == chinese }) else { continue }
                    var sentence = ExampleSentence(
                        chinese: chinese,
                        english: Self.clean(item.english),
                        containsTarget: word.isUsed(in: chinese)
                    )
                    if sentence.containsTarget, checksSense, word.senses.count > 1 {
                        sentence.judgedSense = try? await judgeSense(of: chinese, for: word)
                    }
                    if sentence.containsTarget {
                        kept.append(sentence)
                    } else {
                        rejected.append(sentence)
                    }
                }
            } catch {
                failure = Self.describe(error)
            }
        }

        // Sentences that passed the sense check come first.
        let ordered = kept.filter { $0.isVerified(for: sense) } + kept.filter { !$0.isVerified(for: sense) }
        let sentences = kept.isEmpty ? rejected : Array(ordered.prefix(sentencesPerSense))
        return SenseExamples(sense: sense, sentences: sentences, attempts: attempts, failure: failure)
    }

    private func requestSentences(for sense: WordSense, of word: TargetWord) async throws -> GeneratedSentences {
        // A fresh session per request keeps earlier senses from leaking into this one.
        let session = LanguageModelSession(instructions: Self.instructions(for: word.script))
        let response = try await session.respond(
            to: Self.prompt(for: sense, of: word),
            generating: GeneratedSentences.self,
            options: GenerationOptions(temperature: temperature)
        )
        return response.content
    }

    /// Asks which of the word's meanings `sentence` uses.
    private func judgeSense(of sentence: String, for word: TargetWord) async throws -> Int? {
        let session = LanguageModelSession(instructions: """
            You are a Chinese dictionary editor. You decide which dictionary meaning \
            a word has in a sentence.
            """)
        let response = try await session.respond(
            to: Self.judgePrompt(for: sentence, of: word),
            generating: SenseJudgement.self,
            options: GenerationOptions(sampling: .greedy)
        )
        let number = response.content.meaningNumber
        return word.senses.indices.contains(number - 1) ? number : nil
    }

    // MARK: Prompting

    static func instructions(for script: ChineseScript) -> String {
        """
        You are a Chinese teacher writing example sentences for a learner \
        at an intermediate level.
        Write short, natural, everyday sentences in \(script.displayName) only.
        Every sentence must contain the target word exactly as it is written. \
        Never replace it with a synonym.
        Give a faithful English translation of each sentence.
        """
    }

    static func prompt(for sense: WordSense, of word: TargetWord) -> String {
        let allSenses = word.senses
            .map { "\($0.number). \(promptDefinition($0.definition))" }
            .joined(separator: "\n")
        return """
        Target word: \(word.characters) (\(word.pinyin))

        Dictionary meanings of \(word.characters):
        \(allSenses)

        Write two different example sentences that use \(word.characters) \
        in meaning \(sense.number) only: "\(promptDefinition(sense.definition))". \
        Do not use \(word.characters) in any of its other meanings, \
        so that a reader can tell which meaning it is from the sentence.
        """
    }

    static func freePrompt(for word: TargetWord) -> String {
        let allSenses = word.senses
            .map { "\($0.number). \(promptDefinition($0.definition))" }
            .joined(separator: "\n")
        return """
        Target word: \(word.characters) (\(word.pinyin))

        Dictionary meanings of \(word.characters):
        \(allSenses)

        Write four different example sentences that use \(word.characters) \
        the way people most often use it in everyday Chinese. \
        For each sentence, give the number of the meaning \(word.characters) has in it.
        """
    }

    static func judgePrompt(for sentence: String, of word: TargetWord) -> String {
        let allSenses = word.senses
            .map { "\($0.number). \(promptDefinition($0.definition))" }
            .joined(separator: "\n")
        return """
        Sentence: \(sentence)

        Meanings of \(word.characters):
        \(allSenses)

        Which meaning does \(word.characters) have in this sentence? Answer with its number.
        """
    }

    /// Drops dictionary markup the model doesn't need, such as pinyin like `[hui3]`
    /// and pronunciation notes like `(Taiwan pr. for this sense is …)`.
    static func promptDefinition(_ definition: String) -> String {
        definition
            .replacingOccurrences(of: #"\s*\([^)]*\bpr\.[^)]*\)"#, with: "", options: .regularExpression)
            .replacingOccurrences(of: #"\[[a-zA-Z0-9 ]+\]"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// The model sometimes leaves markdown bold inside a sentence
    /// or stray quote marks and commas around it.
    static func clean(_ text: String) -> String {
        var text = text
            .replacingOccurrences(of: "**", with: "")
            .replacingOccurrences(of: #"\s+(?=\p{Han}|[。，！？])|(?<=\p{Han})\s+"#, with: "", options: .regularExpression)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        let stray: Set<Character> = ["「", "」", "『", "』", "\"", "“", "”", ",", "，"]
        while let last = text.last, stray.contains(last) { text.removeLast() }
        while let first = text.first, stray.contains(first) { text.removeFirst() }
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func describe(_ error: Error) -> String {
        if let error = error as? LanguageModelSession.GenerationError {
            switch error {
            case .guardrailViolation:
                return "Blocked by the model's safety guardrails."
            case .unsupportedLanguageOrLocale:
                return "The model doesn't support this language."
            case .exceededContextWindowSize:
                return "The prompt was too long for the model."
            default:
                return error.localizedDescription
            }
        }
        return error.localizedDescription
    }
}

// MARK: - Model output

@Generable
struct GeneratedSentences {
    @Guide(description: "Example sentences that each use the target word in the requested meaning", .count(2))
    var sentences: [GeneratedSentence]
}

@Generable
struct GeneratedSentence {
    @Guide(description: "One natural Chinese sentence that contains the target word exactly as written")
    var chinese: String

    @Guide(description: "A faithful English translation of the Chinese sentence")
    var english: String
}

@Generable
struct SenseJudgement {
    @Guide(description: "The number of the meaning the word has in the sentence")
    var meaningNumber: Int
}

@Generable
struct GeneratedLabelledSentences {
    @Guide(description: "Different example sentences that each use the target word", .count(4))
    var sentences: [GeneratedLabelledSentence]
}

@Generable
struct GeneratedLabelledSentence {
    @Guide(description: "One natural Chinese sentence that contains the target word exactly as written")
    var chinese: String

    @Guide(description: "A faithful English translation of the Chinese sentence")
    var english: String

    @Guide(description: "The number of the dictionary meaning the target word has in this sentence")
    var meaningNumber: Int
}
