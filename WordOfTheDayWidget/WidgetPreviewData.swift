//
//  WidgetPreviewData.swift
//  ChineseWordOfTheDay
//
//  Created by m on 3/15/26.
//

import CoreDataModels

enum WidgetPreviewWords {
    static let all: [MockWord] = [
        .placeholder,
        .twoCharacters,
        .threeCharacters,
        .fourCharacters,
        .longMeaning,
        .manyMeanings,
        .fourCharactersLongMeaning
    ]
}

enum WidgetPreviewEntries {
    static let twoCharacters = WordEntry(
        date: Date(),
        word: MockWord.twoCharacters,
        selectedMeaning: "to rest"
    )

    static let threeCharacters = WordEntry(
        date: Date(),
        word: MockWord.threeCharacters,
        selectedMeaning: "subway station"
    )

    static let fourCharacters = WordEntry(
        date: Date(),
        word: MockWord.fourCharacters,
        selectedMeaning: "to infer many things from one example"
    )

    static let longMeaning = WordEntry(
        date: Date(),
        word: MockWord.longMeaning,
        selectedMeaning: "to reflect on carefully and deeply before making a decision"
    )

    static let manyMeanings = WordEntry(
        date: Date(),
        word: MockWord.manyMeanings,
        selectedMeaning: "to speak"
    )

    static let fourCharactersLongMeaning = WordEntry(
        date: Date(),
        word: MockWord.fourCharactersLongMeaning,
        selectedMeaning: "to make something already good even better"
    )

    static let wordOnlyTwoCharacters = WordEntry(
        date: Date(),
        word: MockWord.twoCharacters,
        selectedMeaning: nil
    )

    static let wordOnlyFourCharacters = WordEntry(
        date: Date(),
        word: MockWord.fourCharacters,
        selectedMeaning: nil
    )
    static let wordOnlyOneCharacter = WordEntry(
        date: Date(),
        word: MockWord.manyMeanings,
        selectedMeaning: nil
    )
    static let wordOnlyThreeCharacters = WordEntry(
        date: Date(),
        word: MockWord.threeCharacters,
        selectedMeaning: nil
    )

    static let allSmall: [(name: String, entry: WordEntry)] = [
        ("2 chars", twoCharacters),
        ("3 chars", threeCharacters),
        ("4 chars", fourCharacters),
        ("Long meaning", longMeaning),
        ("Many meanings", manyMeanings),
        ("4 chars long meaning", fourCharactersLongMeaning),
        ("Word only 1", wordOnlyOneCharacter),
            ("Word only 2", wordOnlyTwoCharacters),
            ("Word only 3", wordOnlyThreeCharacters),
            ("Word only 4", wordOnlyFourCharacters)
    ]
}
