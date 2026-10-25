//
//  ExampleSentenceGenerator.swift
//  ExampleSentences
//

import Foundation
import FoundationModels

/// One example sentence, in both scripts with readings.
public struct ExampleSentence: Sendable, Hashable, Identifiable {
    public let id = UUID()
    public let traditional: String
    public let simplified: String
    /// One zhuyin syllable per Chinese character of `traditional`, in order.
    public let zhuyin: [String]
    /// One pinyin syllable, with tone marks, per Chinese character of `traditional`, in order.
    public let pinyin: [String]
    public let english: String

    /// The Chinese characters of the sentence, without punctuation.
    /// `zhuyin` and `pinyin` line up with these.
    public var characters: [Character] {
        traditional.filter(Readings.isChineseCharacter).map { $0 }
    }

    /// Characters paired with their readings, for display.
    public var annotatedCharacters: [(character: Character, pinyin: String, zhuyin: String)] {
        characters.enumerated().map { offset, character in
            (character,
             pinyin.indices.contains(offset) ? pinyin[offset] : "",
             zhuyin.indices.contains(offset) ? zhuyin[offset] : "")
        }
    }
}

extension ExampleSentence {
    /// Builds the simplified sentence and readings from the traditional one.
    init(traditional: String, english: String, word: TargetWord) {
        let readings = Readings.readings(of: traditional, word: word)
        self.init(
            traditional: traditional,
            simplified: Readings.simplified(traditional),
            zhuyin: readings.zhuyin,
            pinyin: readings.pinyin,
            english: english
        )
    }
}

/// Example sentences generated for a word.
public struct ExampleSentenceResult: Sendable, Hashable {
    public let word: TargetWord
    /// Every sentence contains the word.
    public let sentences: [ExampleSentence]
    /// How many model calls it took.
    public let attempts: Int
    /// Set when the model produced nothing usable.
    public let failure: String?

    /// A plain-text summary for logs, the command line tools and tests.
    public var report: String {
        var lines = ["\(word.traditional) / \(word.simplified) (\(word.pinyin), \(word.zhuyin)) — \(sentences.count) sentences"]
        if let failure {
            lines.append("  ! \(failure)")
        }
        for sentence in sentences {
            lines.append("  \(sentence.traditional)")
            lines.append("  \(sentence.simplified)")
            lines.append("  \(sentence.pinyin.joined(separator: " "))")
            lines.append("  \(sentence.zhuyin.joined(separator: " "))")
            lines.append("  \(sentence.english)")
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}

/// Writes example sentences for a word with Apple's on-device foundation model.
///
/// The model writes only the traditional sentence and its English translation.
/// The simplified sentence, pinyin and zhuyin are derived from it in code
/// (see `Readings`), because the model gets those wrong.
public struct ExampleSentenceGenerator: Sendable {
    /// How many sentences to return.
    public var sentenceCount: Int
    /// Model calls before giving up on getting `sentenceCount` sentences that use the word.
    public var maxAttempts: Int
    public var temperature: Double

    public init(sentenceCount: Int = 3, maxAttempts: Int = 3, temperature: Double = 0.7) {
        self.sentenceCount = sentenceCount
        self.maxAttempts = maxAttempts
        self.temperature = temperature
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

    /// Generates sentences that use `word`. Sentences missing the word are dropped
    /// and topped up with another call, up to `maxAttempts`.
    public func generate(for word: TargetWord) async -> ExampleSentenceResult {
        var sentences: [ExampleSentence] = []
        var failure: String?
        var attempts = 0

        while sentences.count < sentenceCount, attempts < maxAttempts {
            attempts += 1
            do {
                let session = LanguageModelSession(instructions: Self.instructions)
                let response = try await session.respond(
                    to: Self.prompt(for: word, count: sentenceCount - sentences.count),
                    generating: GeneratedSentences.self,
                    options: GenerationOptions(temperature: temperature)
                )
                failure = nil
                for item in response.content.sentences where sentences.count < sentenceCount {
                    // The model often writes simplified characters when asked for traditional.
                    let traditional = Readings.traditional(Self.clean(item.traditionalSentence))
                    guard traditional.contains(word.traditional),
                          Self.isFullSentence(traditional, word: word),
                          !sentences.contains(where: { $0.traditional == traditional }) else { continue }
                    sentences.append(ExampleSentence(
                        traditional: traditional,
                        english: Self.clean(item.englishTranslation),
                        word: word
                    ))
                }
            } catch {
                failure = Self.describe(error)
            }
        }

        return ExampleSentenceResult(
            word: word,
            sentences: sentences,
            attempts: attempts,
            failure: sentences.isEmpty ? failure : nil
        )
    }

    // MARK: Prompting

    static let instructions = """
        You are a Chinese teacher writing example sentences for a learner \
        at an intermediate level.
        Write short, natural, everyday sentences in Traditional Chinese. \
        Each one must be a complete sentence with a subject and a verb, \
        not a phrase or a single word.
        Every sentence must contain the target word exactly as it is written. \
        Never replace it with a synonym.
        Give a faithful English translation of each sentence.
        """

    static func prompt(for word: TargetWord, count: Int) -> String {
        let definitions = word.definitions.map { "- \(promptDefinition($0))" }.joined(separator: "\n")
        return """
        Target word: \(word.traditional) (\(word.pinyin))

        Meanings:
        \(definitions)

        Write \(count) different example sentences that use \(word.traditional). \
        Start each sentence differently and give each one a different topic.
        """
    }

    /// Rejects bare phrases like 打電話: a sentence needs a few characters besides the word.
    static func isFullSentence(_ sentence: String, word: TargetWord) -> Bool {
        let count = sentence.filter(Readings.isChineseCharacter).count
        return count >= word.traditional.count + 3
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
    @Guide(description: "Different example sentences that each use the target word")
    var sentences: [GeneratedSentence]
}

@Generable
struct GeneratedSentence {
    @Guide(description: "One natural sentence in Traditional Chinese that contains the target word")
    var traditionalSentence: String

    @Guide(description: "A faithful English translation of the sentence")
    var englishTranslation: String
}
