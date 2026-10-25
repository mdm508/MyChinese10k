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

// Xcode's console is a pipe, so print output would otherwise wait until exit.
setvbuf(stdout, nil, _IOLBF, 0)
print("Generating… the on-device model takes a few seconds.")

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
    zhuyin: "ㄉㄚˇ",
    meanings: ["to hit; to strike", "to play (a game)", "to make (a phone call)"]
)

let result = await ExampleSentenceGenerator().generate(for: word)
print(result.report)

// Each sentence is a plain struct:
if let first = result.sentences.first {
    print("traditional:", first.traditional)
    print("simplified: ", first.simplified)
    print("pinyin:     ", first.pinyin)
    print("zhuyin:     ", first.zhuyin)
    print("english:    ", first.english)
}
