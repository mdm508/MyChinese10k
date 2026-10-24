//
//  TargetWord+Samples.swift
//  ExampleSentences
//

import CoreDataModels

public extension TargetWord {
    /// Words with a range of sense counts, for the debug screen, the command line tool and tests.
    /// The dictionary entries are copied from the app's seed data.
    static let samples: [TargetWord] = [
        TargetWord(MockWord.placeholder),
        TargetWord(MockWord.manyMeanings),
        TargetWord(
            index: 1,
            simplified: "的",
            traditional: "的",
            pinyin: "de",
            meanings: [
                "(used after an attribute)",
                "of; ~'s (possessive particle)",
                "(used to form a nominal expression)",
                "also pr. [di4] or [di5] in poetry and songs",
                "(used at the end of a declarative sentence for emphasis)",
            ],
            script: .traditional
        ),
        TargetWord(
            index: 2,
            simplified: "是",
            traditional: "是",
            pinyin: "shì",
            meanings: [
                "correct; right; true",
                "(adverb for emphatic assertion)",
                "to be (followed by substantives only)",
                "(respectful acknowledgement of a command) very well",
            ],
            script: .traditional
        ),
        TargetWord(
            index: 17,
            simplified: "会",
            traditional: "會",
            pinyin: "huì",
            meanings: [
                "group", "union", "meeting", "sure to", "to meet", "gathering", "likely to",
                "association", "to get together", "can (i.e. have the skill, know how to)",
                "a moment (Taiwan pr. for this sense is [hui3])",
            ],
            script: .traditional
        ),
    ]
}
