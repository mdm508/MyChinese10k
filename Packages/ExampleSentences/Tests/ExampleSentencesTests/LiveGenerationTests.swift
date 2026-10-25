//
//  LiveGenerationTests.swift
//  ExampleSentencesTests
//
//  Runs the real on-device model, so it only runs on a device or Mac with
//  Apple Intelligence turned on. The generated sentences are printed to the
//  test log for reading:
//
//      swift test --filter LiveGenerationTests
//

import Testing
@testable import ExampleSentences

@Suite(.enabled(if: ExampleSentenceGenerator.isModelAvailable, "Needs Apple Intelligence"), .serialized)
struct LiveGenerationTests {
    @Test(arguments: TargetWord.samples)
    func sentencesUseTheWordAndReadingsLineUp(word: TargetWord) async {
        let result = await ExampleSentenceGenerator().generate(for: word)
        print(result.report)

        #expect(!result.sentences.isEmpty, "No sentences for \(word.traditional)")
        for sentence in result.sentences {
            #expect(sentence.traditional.contains(word.traditional))
            #expect(sentence.simplified.contains(word.simplified))
            #expect(sentence.pinyin.count == sentence.characters.count)
            #expect(sentence.zhuyin.count == sentence.characters.count)
        }
    }
}
