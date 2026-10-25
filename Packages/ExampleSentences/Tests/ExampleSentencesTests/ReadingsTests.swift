//
//  ReadingsTests.swift
//  ExampleSentencesTests
//

import Testing
import CoreDataModels
@testable import ExampleSentences

struct ReadingsTests {
    private let xuexi = TargetWord(MockWord.placeholder)

    @Test func readingsLineUpWithCharactersAndSkipPunctuation() {
        let sentence = ExampleSentence(traditional: "我每天學習中文。", english: "I study Chinese every day.", word: xuexi)
        #expect(sentence.characters.map(String.init) == ["我", "每", "天", "學", "習", "中", "文"])
        #expect(sentence.pinyin.count == 7)
        #expect(sentence.zhuyin.count == 7)
        #expect(sentence.pinyin == ["wǒ", "měi", "tiān", "xué", "xí", "zhōng", "wén"])
        #expect(sentence.zhuyin[0] == "ㄨㄛˇ")
    }

    @Test func simplifiedIsDerivedFromTraditional() {
        let sentence = ExampleSentence(traditional: "我每天學習中文。", english: "", word: xuexi)
        #expect(sentence.simplified == "我每天学习中文。")
    }

    @Test func simplifiedInputIsConvertedToTraditional() {
        #expect(Readings.traditional("我每天学习中文") == "我每天學習中文")
    }

    @Test func targetWordUsesDictionaryReadings() {
        // ICU reads 會 as huì everywhere; the dictionary entry wins for the target word.
        let moment = TargetWord(index: 0, simplified: "会", traditional: "會", pinyin: "huǐ", zhuyin: "ㄏㄨㄟˇ", meanings: ["a moment"])
        let sentence = ExampleSentence(traditional: "等一會。", english: "Wait a moment.", word: moment)
        #expect(sentence.pinyin == ["děng", "yī", "huǐ"])
        #expect(sentence.zhuyin.last == "ㄏㄨㄟˇ")
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
}
