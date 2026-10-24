//
//  main.swift
//  example-sentences
//
//  Prints AI example sentences for words, one block per word.
//
//  swift run example-sentences                       # the built-in sample words
//  swift run example-sentences --data output.json 是 學習 17
//  swift run example-sentences --data output.json --simplified 学习
//
//  Words can be given in either script or by their frequency index.
//  Requires a Mac with Apple Intelligence turned on.
//

import Foundation
import CoreDataModels
import ExampleSentences

/// An entry of the dataset's output.json.
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

func fail(_ message: String) -> Never {
    FileHandle.standardError.write(Data((message + "\n").utf8))
    exit(1)
}

var arguments = Array(CommandLine.arguments.dropFirst())
var dataURL: URL?
var script = ChineseScript.traditional
var queries: [String] = []

while !arguments.isEmpty {
    let argument = arguments.removeFirst()
    switch argument {
    case "--data":
        guard !arguments.isEmpty else { fail("--data needs a path to output.json") }
        dataURL = URL(fileURLWithPath: arguments.removeFirst())
    case "--simplified":
        script = .simplified
    case "--traditional":
        script = .traditional
    case "-h", "--help":
        print("usage: example-sentences [--data output.json] [--simplified] [word or index ...]")
        exit(0)
    default:
        queries.append(argument)
    }
}

var words: [TargetWord]
if queries.isEmpty {
    words = TargetWord.samples
} else {
    guard let dataURL else { fail("Looking words up needs --data <path to output.json>") }
    let dataset: [DatasetWord]
    do {
        dataset = try JSONDecoder().decode([DatasetWord].self, from: Data(contentsOf: dataURL))
    } catch {
        fail("Couldn't read \(dataURL.path): \(error)")
    }
    words = queries.map { query in
        let match = dataset.first {
            $0.traditional == query || $0.simplified == query || String($0.index) == query
        }
        guard let match else { fail("No word \(query) in \(dataURL.lastPathComponent)") }
        return TargetWord(match, script: script)
    }
}

if let reason = ExampleSentenceGenerator.unavailableReason {
    fail(reason)
}

let generator = ExampleSentenceGenerator()
var allCovered = true
for word in words {
    let result = await generator.generate(for: word)
    allCovered = allCovered && result.coversEverySense
    print(result.report)
    print()
}
exit(allCovered ? 0 : 2)
