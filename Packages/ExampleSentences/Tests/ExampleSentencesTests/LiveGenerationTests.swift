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
    func everySenseGetsASentenceUsingTheWord(word: TargetWord) async {
        let result = await ExampleSentenceGenerator().generate(for: word)
        print(result.report)

        #expect(result.senses.count == word.senses.count)
        for examples in result.senses {
            #expect(examples.isCovered, "No sentence uses \(word.characters) for sense \(examples.sense.number): \(examples.sense.definition)")
        }
    }
}
