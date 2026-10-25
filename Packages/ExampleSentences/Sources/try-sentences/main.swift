//
//  main.swift
//  try-sentences
//
//  A scratch file for trying the generator. Edit the word below, then in Xcode
//  pick the "try-sentences" scheme with "My Mac" as the destination and press ⌘R.
//  Output appears in the debug console. From Terminal: swift run try-sentences
//  Needs Apple Intelligence turned on.
//

import Foundation
import CoreDataModels
import ExampleSentences

if let reason = ExampleSentenceGenerator.unavailableReason {
    print(reason)
    exit(1)
}

// Any word from the app works: TargetWord(MockWord.placeholder), or a Core Data `Word`.
let word = TargetWord(
    index: 0,
    simplified: "打",
    traditional: "打",
    pinyin: "dǎ",
    meanings: ["to hit; to strike", "to play (a game)", "to make (a phone call)"],
    script: .traditional
)

let generator = ExampleSentenceGenerator()

// Sentences for every meaning.
let result = await generator.generate(for: word)
print(result.report)
print("All meanings covered:", result.coversEverySense)
print()

// Free mode: four sentences, the model picks the meanings.
let free = await generator.freeExamples(for: word)
print(free.report)
