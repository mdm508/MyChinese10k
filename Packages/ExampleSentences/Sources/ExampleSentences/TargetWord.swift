//
//  TargetWord.swift
//  ExampleSentences
//

import Foundation
import CoreDataModels

/// A `Sendable` snapshot of a word that the generator works from.
///
/// Build one from any `WordRepresentable` (a Core Data `Word` or a `MockWord`)
/// on the thread that owns it, then hand it to `ExampleSentenceGenerator`.
public struct TargetWord: Sendable, Hashable, Identifiable {
    public let index: Int64
    public let simplified: String
    public let traditional: String
    public let pinyin: String
    public let zhuyin: String
    public let meanings: [String]

    public var id: Int64 { index }

    /// Meanings worth showing the model, without dictionary notes such as
    /// pronunciation notes, variant pointers and classifiers.
    public var definitions: [String] {
        var seen = Set<String>()
        return meanings
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && !Self.isNote($0) && seen.insert($0).inserted }
    }

    public init(
        index: Int64,
        simplified: String,
        traditional: String,
        pinyin: String,
        zhuyin: String,
        meanings: [String]
    ) {
        self.index = index
        self.simplified = simplified
        self.traditional = traditional
        self.pinyin = pinyin.trimmingCharacters(in: .whitespacesAndNewlines)
        self.zhuyin = zhuyin.trimmingCharacters(in: .whitespacesAndNewlines)
        self.meanings = meanings
    }

    public init(_ word: some WordRepresentable) {
        self.init(
            index: word.index,
            simplified: word.simplified,
            traditional: word.traditional,
            pinyin: word.pinyin,
            zhuyin: word.zhuyin,
            meanings: word.meanings
        )
    }

    /// Meanings starting with these are notes about the entry, not meanings of the word.
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
        let text = meaning.lowercased()
        return notePrefixes.contains { text.hasPrefix($0) }
    }
}

extension TargetWord: WordRepresentable {
    public var context: [String] { [] }
    public var characters: String { traditional }
    public var phonetic: String { pinyin }
}
