//
//  SenseTests.swift
//  ExampleSentencesTests
//

import Testing
import CoreDataModels
@testable import ExampleSentences

struct SenseTests {
    @Test func eachMeaningIsOneSense() {
        let word = TargetWord(MockWord.manyMeanings)
        #expect(word.senses.map(\.definition) == MockWord.manyMeanings.meanings)
        #expect(word.senses.map(\.number) == Array(1...6))
    }

    @Test func synonymsInOneMeaningStayOneSense() {
        let word = TargetWord.samples.first { $0.traditional == "是" }!
        #expect(word.senses.count == 4)
        #expect(word.senses[0].definition == "correct; right; true")
    }

    @Test func pronunciationNotesAreNotSenses() {
        let word = TargetWord.samples.first { $0.traditional == "的" }!
        #expect(word.senses.count == 4)
        #expect(word.notes == ["also pr. [di4] or [di5] in poetry and songs"])
    }

    @Test(arguments: ["variant of 個|个[ge4]", "old variant of 為|为[wei2]", "see also 自個兒|自个儿", "CL:個|个[ge4]"])
    func dictionaryNotesAreSkipped(meaning: String) {
        #expect(SenseParser.isNote(meaning))
    }

    @Test func scriptFollowsTheDisplayedCharacters() {
        #expect(TargetWord(MockWord.placeholder).script == .traditional)
        #expect(TargetWord(MockWord.placeholder).characters == "學習")

        var simplified = MockWord.placeholder
        simplified.characters = simplified.simplified
        #expect(TargetWord(simplified).script == .simplified)
    }

    @Test func eitherScriptCountsAsUsingTheWord() {
        let word = TargetWord(MockWord.placeholder)
        #expect(word.isUsed(in: "我每天學習中文。"))
        #expect(word.isUsed(in: "我每天学习中文。"))
        #expect(!word.isUsed(in: "我每天讀書。"))
    }

    @Test func promptDropsPronunciationMarkup() {
        #expect(ExampleSentenceGenerator.promptDefinition("a moment (Taiwan pr. for this sense is [hui3])") == "a moment")
        #expect(ExampleSentenceGenerator.promptDefinition("(often followed by 著|着[zhe5]) taking advantage of") == "(often followed by 著|着) taking advantage of")
        #expect(ExampleSentenceGenerator.promptDefinition("correct; right; true") == "correct; right; true")
    }

    @Test func strayQuotesAreTrimmedFromSentences() {
        #expect(ExampleSentenceGenerator.clean("這位老師會在下課後給我們解釋。」,") == "這位老師會在下課後給我們解釋。")
        #expect(ExampleSentenceGenerator.clean("「我會去。」") == "我會去。")
        #expect(ExampleSentenceGenerator.clean("He said, \"OK.\"") == "He said, \"OK.")
        #expect(ExampleSentenceGenerator.clean("我們要參加一個新的公司 **會**。") == "我們要參加一個新的公司會。")
        #expect(ExampleSentenceGenerator.clean("We attended two **meetings**.") == "We attended two meetings.")
    }
}
