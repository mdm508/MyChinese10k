//
//  TargetWord.swift
//  ExampleSentences
//

import Foundation
import CoreDataModels

/// The writing system example sentences are generated in.
public enum ChineseScript: String, Sendable, Hashable, CaseIterable {
    case traditional
    case simplified

    var displayName: String {
        switch self {
        case .traditional: return "Traditional Chinese"
        case .simplified: return "Simplified Chinese"
        }
    }
}

/// One sense of a word, taken from a single entry of its English `meanings`.
///
/// CC-CEDICT style meanings put one sense per entry and separate synonyms
/// inside that sense with ";", so `"stratagem; scheme; plot"` is one sense.
public struct WordSense: Sendable, Hashable, Identifiable {
    /// Position of the sense among the word's senses, starting at 1.
    public let number: Int
    /// The definition text exactly as it appears in `meanings`.
    public let definition: String

    public var id: Int { number }
}

/// A `Sendable` snapshot of a word that the generator works from.
///
/// Build one from any `WordRepresentable` (a Core Data `Word` or a `MockWord`)
/// on the thread that owns it, then hand it to `ExampleSentenceGenerator`.
public struct TargetWord: Sendable, Hashable, Identifiable {
    public let index: Int64
    public let simplified: String
    public let traditional: String
    public let pinyin: String
    public let meanings: [String]
    public let script: ChineseScript

    public var id: Int64 { index }

    /// The form of the word every sentence must contain.
    public var characters: String {
        script == .simplified ? simplified : traditional
    }

    /// Meanings that describe what the word means, in order.
    public var senses: [WordSense] {
        SenseParser.senses(from: meanings)
    }

    /// Meanings that are dictionary notes rather than senses
    /// (pronunciation notes, variant pointers, classifiers).
    public var notes: [String] {
        meanings.filter(SenseParser.isNote)
    }

    public init(
        index: Int64,
        simplified: String,
        traditional: String,
        pinyin: String,
        meanings: [String],
        script: ChineseScript
    ) {
        self.index = index
        self.simplified = simplified
        self.traditional = traditional
        self.pinyin = pinyin.trimmingCharacters(in: .whitespacesAndNewlines)
        self.meanings = meanings
        self.script = script
    }

    /// Takes the script from the form `word.characters` is showing, which follows
    /// the user's writing system setting for a Core Data `Word`.
    public init(_ word: some WordRepresentable) {
        let script: ChineseScript =
            word.characters == word.simplified && word.simplified != word.traditional
            ? .simplified
            : .traditional
        self.init(word, script: script)
    }

    public init(_ word: some WordRepresentable, script: ChineseScript) {
        self.init(
            index: word.index,
            simplified: word.simplified,
            traditional: word.traditional,
            pinyin: word.pinyin,
            meanings: word.meanings,
            script: script
        )
    }

    /// Whether `sentence` uses the word, in either script.
    public func isUsed(in sentence: String) -> Bool {
        sentence.contains(characters)
            || sentence.contains(simplified)
            || sentence.contains(traditional)
    }
}

enum SenseParser {
    /// Meanings starting with these are notes about the entry, not senses of the word.
    private static let notePrefixes = [
        "also pr.",
        "also pronounced",
        "also written",
        "old variant of",
        "variant of",
        "see also",
        "see ",
        "cl:",
    ]

    static func isNote(_ meaning: String) -> Bool {
        let text = meaning.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return notePrefixes.contains { text.hasPrefix($0) }
    }

    static func senses(from meanings: [String]) -> [WordSense] {
        var seen = Set<String>()
        var senses: [WordSense] = []
        for meaning in meanings {
            let definition = meaning.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !definition.isEmpty, !isNote(definition), seen.insert(definition).inserted else {
                continue
            }
            senses.append(WordSense(number: senses.count + 1, definition: definition))
        }
        return senses
    }
}
