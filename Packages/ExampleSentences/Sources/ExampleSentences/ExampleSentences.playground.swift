//
//  ExampleSentences.playground.swift
//  ExampleSentences
//
//  Open Packages/ExampleSentences/Package.swift (or the app project) in Xcode 26,
//  open this file and show the canvas (⌥⌘↩). Choose "My Mac" as the run
//  destination. Each #Playground block is a tab in the canvas; its values and
//  printed output appear there, not in Xcode's debug console. A block takes
//  10–40 seconds while the model runs. Needs Apple Intelligence turned on.
//

#if DEBUG
import Playgrounds
import CoreDataModels

// 1. Any word from the app: a MockWord here, a Core Data `Word` works the same way.
#Playground("Every sense of 學習") {
    let available = ExampleSentenceGenerator.unavailableReason ?? "Model ready"
    let word = TargetWord(MockWord.placeholder)
    let result = await ExampleSentenceGenerator().generate(for: word)
    let report = result.report
    let allCovered = result.coversEverySense
}

// 2. Your own word: edit the meanings and watch which senses get sentences.
#Playground("Every sense of a custom word") {
    let word = TargetWord(
        index: 0,
        simplified: "打",
        traditional: "打",
        pinyin: "dǎ",
        meanings: ["to hit; to strike", "to play (a game)", "to make (a phone call)"],
        script: .traditional
    )
    let result = await ExampleSentenceGenerator().generate(for: word)
    let report = result.report
}

// 3. Free mode: four sentences, the model picks the meanings. Faster.
#Playground("Free mode for 會") {
    let word = TargetWord.samples.first { $0.traditional == "會" }!
    let result = await ExampleSentenceGenerator().freeExamples(for: word)
    let report = result.report
}

// 4. One sense at a time, without the sense check, to compare quickly.
#Playground("One sense of 說, no sense check") {
    let word = TargetWord(MockWord.manyMeanings)
    let generator = ExampleSentenceGenerator(sentencesPerSense: 3, checksSense: false)
    let examples = await generator.examples(for: word.senses[4], of: word)  // "to tell"
    let sentences = examples.sentences.map { "\($0.chinese) — \($0.english)\($0.containsTarget ? "" : " [missing 說]")" }
}
#endif
