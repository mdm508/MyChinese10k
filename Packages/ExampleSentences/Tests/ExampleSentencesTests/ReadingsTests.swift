//
//  ReadingsTests.swift
//  ExampleSentencesTests
//

import Testing
import CoreDataModels
@testable import ExampleSentences

struct ReadingsTests {
    private let xuexi = TargetWord(MockWord.placeholder)

    @Test func sentenceIsSplitIntoAlignedWords() {
        let sentence = ExampleSentence(traditional: "我每天學習中文。", english: "I study Chinese every day.", word: xuexi, dictionary: ReadingDictionary())
        #expect(sentence.traditionalText == "我每天學習中文。")
        #expect(sentence.simplifiedText == "我每天学习中文。")
        let count = sentence.traditional.count
        #expect(count > 1)
        #expect(sentence.simplified.count == count)
        #expect(sentence.pinyin.count == count)
        #expect(sentence.zhuyin.count == count)
        #expect(sentence.dictionaryIndices.count == count)
        // Punctuation stays with the word before it.
        #expect(sentence.traditional.last?.hasSuffix("。") == true)
    }

    @Test func targetWordIsOneSegmentWithDictionaryReadings() {
        let sentence = ExampleSentence(traditional: "我每天學習中文。", english: "", word: xuexi, dictionary: ReadingDictionary())
        let position = sentence.traditional.firstIndex(of: "學習")
        #expect(position != nil)
        if let position {
            #expect(sentence.pinyin[position] == xuexi.pinyin)
            #expect(sentence.zhuyin[position] == xuexi.zhuyin)
            #expect(sentence.dictionaryIndices[position] == xuexi.index)
        }
    }

    @Test func otherWordsUseTheReadingDictionary() {
        let yinyue = TargetWord(index: 42, simplified: "音乐", traditional: "音樂", pinyin: "yīnyuè", zhuyin: "ㄧㄣ ㄩㄝˋ", meanings: ["music"])
        let dictionary = ReadingDictionary([yinyue])
        let sentence = ExampleSentence(traditional: "我在學習音樂", english: "", word: xuexi, dictionary: dictionary)
        if let position = sentence.traditional.firstIndex(of: "音樂") {
            #expect(sentence.pinyin[position] == "yīnyuè")
            #expect(sentence.dictionaryIndices[position] == 42)
        } else {
            Issue.record("音樂 wasn't one segment: \(sentence.traditional)")
        }
    }

    @Test func icuReadingsFillInWordsNotInTheDictionary() {
        let sentence = ExampleSentence(traditional: "我每天學習中文", english: "", word: xuexi, dictionary: ReadingDictionary())
        #expect(sentence.pinyin.first == "wǒ")
        #expect(sentence.zhuyin.first == "ㄨㄛˇ")
    }

    @Test func simplifiedInputIsConvertedToTraditional() {
        #expect(Readings.traditional("我每天学习中文") == "我每天學習中文")
    }

    @Test func dictionaryNotesAreLeftOutOfThePrompt() {
        let de = TargetWord.samples.first { $0.traditional == "的" }!
        #expect(de.definitions.count == 4)
        #expect(!ExampleSentenceGenerator.prompt(for: de, count: 3).contains("also pr."))
    }

    @Test func promptDropsPronunciationMarkup() {
        #expect(ExampleSentenceGenerator.promptDefinition("a moment (Taiwan pr. for this sense is [hui3])") == "a moment")
        #expect(ExampleSentenceGenerator.promptDefinition("correct; right; true") == "correct; right; true")
    }

    @Test func strayMarkupIsTrimmedFromSentences() {
        #expect(ExampleSentenceGenerator.clean("這位老師會在下課後給我們解釋。」,") == "這位老師會在下課後給我們解釋。")
        #expect(ExampleSentenceGenerator.clean("我們要參加一個新的公司 **會**。") == "我們要參加一個新的公司會。")
    }

    @Test func barePhrasesAreRejected() {
        let da = TargetWord(index: 0, simplified: "打", traditional: "打", pinyin: "dǎ", zhuyin: "ㄉㄚˇ", meanings: ["to hit"])
        #expect(!ExampleSentenceGenerator.isFullSentence("打電話", word: da))
        #expect(ExampleSentenceGenerator.isFullSentence("我晚上打電話給你。", word: da))
    }

    @Test func readingsAreNormalized() {
        #expect(Readings.normalizedPinyin("jù huì") == "jùhuì")
        #expect(Readings.normalizedZhuyin("ㄨㄛˇ ㄇㄣ˙") == "ㄨㄛˇ ˙ㄇㄣ")
        #expect(Readings.normalizedZhuyin("ㄉㄜ˙") == "˙ㄉㄜ")
    }

    @Test func particleZheIsNeutral() {
        let sentence = ExampleSentence(traditional: "他笑著學習", english: "", word: xuexi, dictionary: ReadingDictionary())
        if let position = sentence.traditional.firstIndex(of: "著") {
            #expect(sentence.pinyin[position] == "zhe")
        }
    }
}
