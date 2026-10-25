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

// Readings for the other words in each sentence come from the dataset when it's
// there; otherwise they get ICU's most common reading of each character.
struct DatasetWord: Decodable, WordRepresentable {
    let context: [String]
    let index: Int64
    let meanings: [String]
    let pinyin: String
    let simplified: String
    let traditional: String
    let zhuyin: String
    var characters: String { traditional }
    var phonetic: String { pinyin }
}
let datasetPath = NSString(string: "~/Developer/chineseWordOfTheDayDataSet/output.json").expandingTildeInPath
let dataset = (try? Data(contentsOf: URL(fileURLWithPath: datasetPath)))
    .flatMap { try? JSONDecoder().decode([DatasetWord].self, from: $0) } ?? []
print("Reading dictionary: \(dataset.count) words")

let result = await ExampleSentenceGenerator(dictionary: ReadingDictionary(dataset)).generate(for: word)
print(result.report)

// Each sentence is a plain struct of word-aligned arrays:
if let first = result.sentences.first {
    print("traditional:", first.traditional)
    print("simplified: ", first.simplified)
    print("pinyin:     ", first.pinyin)
    print("zhuyin:     ", first.zhuyin)
    print("english:    ", first.english)
}
