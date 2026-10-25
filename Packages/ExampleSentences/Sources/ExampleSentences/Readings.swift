//
//  Readings.swift
//  ExampleSentences
//

import Foundation
import NaturalLanguage
import CoreDataModels

/// Readings for words, looked up by their traditional form.
///
/// Build one from the app's word list so sentence words get dictionary readings
/// (音樂 yīnyuè rather than ICU's yīn lè) and a link back to their entry.
public struct ReadingDictionary: Sendable {
    public struct Entry: Sendable, Hashable {
        public let index: Int64
        public let pinyin: String
        public let zhuyin: String
    }

    private var entries: [String: Entry] = [:]

    public init() {}

    public init<Words: Sequence>(_ words: Words) where Words.Element: WordRepresentable {
        for word in words where entries[word.traditional] == nil {
            entries[word.traditional] = Entry(
                index: word.index,
                pinyin: word.pinyin.trimmingCharacters(in: .whitespaces),
                zhuyin: word.zhuyin.trimmingCharacters(in: .whitespaces)
            )
        }
    }

    public var count: Int { entries.count }

    public subscript(traditional: String) -> Entry? {
        entries[traditional]
    }
}

/// Word segmentation, script conversion and readings, all with frameworks built
/// into the OS: NaturalLanguage's tokenizer for words and Foundation's ICU
/// transforms for scripts and readings.
///
/// The on-device model is unreliable at these: asked for per-character pinyin
/// and zhuyin it got 12 of 12 test sentences wrong, and it can't line its output
/// up with the characters.
enum Readings {
    /// One word of a sentence, with any punctuation that follows it.
    struct Segment: Hashable {
        var traditional: String
        var simplified: String
        var pinyin: String
        var zhuyin: String
        /// The word's index in the dictionary, when it was found there.
        var dictionaryIndex: Int64?
    }

    static func isChineseCharacter(_ character: Character) -> Bool {
        character.unicodeScalars.allSatisfy(\.properties.isIdeographic)
    }

    static func traditional(_ text: String) -> String {
        text.applyingTransform(StringTransform("Hans-Hant"), reverse: false) ?? text
    }

    static func simplified(_ text: String) -> String {
        text.applyingTransform(StringTransform("Hant-Hans"), reverse: false) ?? text
    }

    /// The most common pinyin reading of one character, with tone marks.
    static func pinyin(of character: Character) -> String {
        String(character).applyingTransform(.mandarinToLatin, reverse: false)?
            .trimmingCharacters(in: .whitespaces) ?? ""
    }

    /// Converts one pinyin syllable with tone marks to zhuyin.
    static func zhuyin(fromPinyin syllable: String) -> String {
        syllable.applyingTransform(StringTransform("Latin-Bopomofo"), reverse: false)?
            .trimmingCharacters(in: .whitespaces) ?? ""
    }

    /// Splits a traditional sentence into words, each with its simplified form,
    /// pinyin (syllables run together, as in "wǒmen") and zhuyin (syllables
    /// separated by spaces). Punctuation stays with the word before it, so the
    /// segments joined together give back the sentence.
    ///
    /// Readings come from, in order: the target word's own entry, `dictionary`,
    /// and ICU's most common reading of each character, which can be wrong for
    /// characters with several readings.
    static func segments(of sentence: String, word: TargetWord, dictionary: ReadingDictionary) -> [Segment] {
        wordTexts(of: sentence, keepingTogether: word.traditional).map { text in
            var segment = rawSegment(text, word: word, dictionary: dictionary)
            segment.pinyin = normalizedPinyin(segment.pinyin)
            segment.zhuyin = normalizedZhuyin(segment.zhuyin)
            return segment
        }
    }

    /// Single-character words ICU reads wrong when they stand alone as particles.
    private static let particles: [String: (pinyin: String, zhuyin: String)] = [
        "著": ("zhe", "˙ㄓㄜ"),
    ]

    /// Pinyin syllables of a word run together, as in "wǒmen" (the dataset and
    /// ICU differ on spacing).
    static func normalizedPinyin(_ pinyin: String) -> String {
        pinyin.filter { !$0.isWhitespace }
    }

    /// Zhuyin syllables separated by single spaces, with the neutral-tone dot
    /// in front Taiwan-style (˙ㄇㄣ), as in the dataset; ICU puts it after.
    static func normalizedZhuyin(_ zhuyin: String) -> String {
        zhuyin.split(whereSeparator: \.isWhitespace).map { syllable in
            syllable.last == "˙" ? "˙" + String(syllable.dropLast()) : String(syllable)
        }
        .joined(separator: " ")
    }

    private static func rawSegment(_ text: String, word: TargetWord, dictionary: ReadingDictionary) -> Segment {
        let characters = text.filter(isChineseCharacter)
        if characters == word.traditional {
            return Segment(
                traditional: text,
                simplified: simplified(text),
                pinyin: word.pinyin,
                zhuyin: word.zhuyin,
                dictionaryIndex: word.index
            )
        }
        if let entry = dictionary[characters] {
            return Segment(
                traditional: text,
                simplified: simplified(text),
                pinyin: entry.pinyin,
                zhuyin: entry.zhuyin,
                dictionaryIndex: entry.index
            )
        }
        if let particle = particles[characters] {
            return Segment(
                traditional: text,
                simplified: simplified(text),
                pinyin: particle.pinyin,
                zhuyin: particle.zhuyin,
                dictionaryIndex: nil
            )
        }
        let syllables = characters.map(pinyin(of:))
        return Segment(
            traditional: text,
            simplified: simplified(text),
            pinyin: syllables.joined(),
            zhuyin: syllables.map(zhuyin(fromPinyin:)).joined(separator: " "),
            dictionaryIndex: nil
        )
    }

    /// The sentence cut into words, with punctuation attached to the word before it.
    static func wordTexts(of sentence: String, keepingTogether target: String) -> [String] {
        let tokenizer = NLTokenizer(unit: .word)
        tokenizer.string = sentence
        tokenizer.setLanguage(.traditionalChinese)
        var tokens = tokenizer.tokens(for: sentence.startIndex..<sentence.endIndex)

        // Merge the tokens that make up the target word, if the tokenizer split it.
        var searchStart = sentence.startIndex
        while !target.isEmpty,
              let occurrence = sentence.range(of: target, range: searchStart..<sentence.endIndex) {
            let inside = tokens.indices.filter { occurrence.contains(tokens[$0].lowerBound) }
            if let first = inside.first, let last = inside.last, inside.count > 1,
               tokens[first].lowerBound == occurrence.lowerBound,
               tokens[last].upperBound == occurrence.upperBound {
                tokens.replaceSubrange(first...last, with: [occurrence])
            }
            searchStart = occurrence.upperBound
        }

        guard !tokens.isEmpty else {
            return sentence.isEmpty ? [] : [sentence]
        }
        // Each word runs to the start of the next one, picking up punctuation.
        // Anything before the first word goes with the first word.
        var texts: [String] = []
        for (offset, token) in tokens.enumerated() {
            let start = offset == 0 ? sentence.startIndex : token.lowerBound
            let end = offset + 1 < tokens.count ? tokens[offset + 1].lowerBound : sentence.endIndex
            let text = sentence[start..<end].filter { !$0.isWhitespace }
            if !text.isEmpty {
                texts.append(String(text))
            }
        }
        return texts
    }
}
