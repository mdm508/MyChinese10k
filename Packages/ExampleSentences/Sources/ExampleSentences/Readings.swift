//
//  Readings.swift
//  ExampleSentences
//

import Foundation

/// Script conversion and readings, using the ICU transforms built into Foundation.
///
/// The on-device model is unreliable at these: asked for per-character pinyin
/// and zhuyin it got 12 of 12 test sentences wrong, while these transforms were
/// right in every case. They are deterministic and instant.
enum Readings {
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

    /// One pinyin and one zhuyin reading per Chinese character of `sentence`.
    ///
    /// ICU picks the most common reading of each character, which can be wrong
    /// for characters with several readings (行, 了, 長). Where the sentence
    /// contains `word`, its readings come from the dictionary entry instead.
    static func readings(of sentence: String, word: TargetWord) -> (pinyin: [String], zhuyin: [String]) {
        let characters = sentence.filter(isChineseCharacter).map { $0 }
        var pinyinReadings = characters.map(Self.pinyin(of:))
        var zhuyinReadings = pinyinReadings.map(Self.zhuyin(fromPinyin:))

        let wordCharacters = word.traditional.filter(isChineseCharacter).map { $0 }
        let wordPinyin = word.pinyin.split(whereSeparator: \.isWhitespace).map(String.init)
        let wordZhuyin = word.zhuyin.split(whereSeparator: \.isWhitespace).map(String.init)
        guard !wordCharacters.isEmpty, wordCharacters.count <= characters.count else {
            return (pinyinReadings, zhuyinReadings)
        }
        for start in 0...(characters.count - wordCharacters.count)
        where Array(characters[start..<start + wordCharacters.count]) == wordCharacters {
            let range = start..<start + wordCharacters.count
            if wordPinyin.count == wordCharacters.count {
                pinyinReadings.replaceSubrange(range, with: wordPinyin)
            }
            if wordZhuyin.count == wordCharacters.count {
                zhuyinReadings.replaceSubrange(range, with: wordZhuyin)
            }
        }
        return (pinyinReadings, zhuyinReadings)
    }
}
