//
//  MockWord.swift
//  ChineseWordOfTheDay
//
//  Created by m on 10/3/24.
//

import Foundation
/// Struct that mirrors the Word entity.
/// It's primary purpose is for use in the widget extension.
/// A MockWord is  what will be stored in `UserDefaults`
/// and displayed by the widget.
public struct MockWord: Identifiable, WordRepresentable {
    public var index: Int64
    public var context: [String]
    public var meanings: [String]
    public var pinyin: String
    public var simplified: String
    public var traditional: String
    public var zhuyin: String
    public var characters: String
    public var phonetic: String
    public var id = UUID()
}


extension MockWord: Encodable, Decodable {
    /// Decodes MockWord from UserDefaults.
    /// Use to share data between main application and widget.
    /// - Parameters:
    ///   - appGroupId:
    ///   - mockWordKey:
    /// - Returns: Most recent word return to `UserDefaults`.
    /// - Precondition: `appGroupId` exists and both the widget and main app are a part of it.
        public static func readFromUserDefaults() -> MockWord? {
            let sharedDefaults = UserDefaults(suiteName: Constants.appGroupId)
            if let savedData = sharedDefaults?.data(forKey: Constants.mockWordKey),
               let decodedWord = try? JSONDecoder().decode(MockWord.self, from: savedData) {
                return decodedWord
            }
            return nil
        }
}

public extension MockWord {
    static var placeholder: MockWord {
        MockWord(
            index: -1,
            context: ["教育"],
            meanings: ["to study", "to learn"],
            pinyin: "xuéxí",
            simplified: "学习",
            traditional: "學習",
            zhuyin: "ㄒㄩㄝˊ ㄒㄧˊ",
            characters: "學習",
            phonetic: "ㄒㄩㄝˊ ㄒㄧˊ"
        )
    }

    static var twoCharacters: MockWord {
        MockWord(
            index: -2,
            context: ["生活"],
            meanings: ["to rest", "to stop and recover energy"],
            pinyin: "xiūxí",
            simplified: "休息",
            traditional: "休息",
            zhuyin: "ㄒㄧㄡ ㄒㄧˊ",
            characters: "休息",
            phonetic: "ㄒㄧㄡ ㄒㄧˊ"
        )
    }

    static var threeCharacters: MockWord {
        MockWord(
            index: -3,
            context: ["交通"],
            meanings: ["subway", "metro", "underground railway system"],
            pinyin: "dìtiě",
            simplified: "地铁",
            traditional: "地鐵站",
            zhuyin: "ㄉㄧˋ ㄊㄧㄝˇ ㄓㄢˋ",
            characters: "地鐵站",
            phonetic: "ㄉㄧˋ ㄊㄧㄝˇ ㄓㄢˋ"
        )
    }

    static var fourCharacters: MockWord {
        MockWord(
            index: -4,
            context: ["成語"],
            meanings: ["to draw inferences about other cases from one instance"],
            pinyin: "jǔ yī fǎn sān",
            simplified: "举一反三",
            traditional: "舉一反三",
            zhuyin: "ㄐㄩˇ ㄧ ㄈㄢˇ ㄙㄢ",
            characters: "舉一反三",
            phonetic: "ㄐㄩˇ ㄧ ㄈㄢˇ ㄙㄢ"
        )
    }

    static var longMeaning: MockWord {
        MockWord(
            index: -5,
            context: ["思考"],
            meanings: [
                "to reflect on carefully and deeply; to turn a subject over in one's mind before making a decision or judgment"
            ],
            pinyin: "sīkǎo",
            simplified: "思考",
            traditional: "思考",
            zhuyin: "ㄙ ㄎㄠˇ",
            characters: "思考",
            phonetic: "ㄙ ㄎㄠˇ"
        )
    }

    static var manyMeanings: MockWord {
        MockWord(
            index: -6,
            context: ["語言"],
            meanings: [
                "to say",
                "to speak",
                "to explain",
                "to express",
                "to tell",
                "to talk about at length"
            ],
            pinyin: "shuō",
            simplified: "说",
            traditional: "說",
            zhuyin: "ㄕㄨㄛ",
            characters: "說",
            phonetic: "ㄕㄨㄛ"
        )
    }

    static var fourCharactersLongMeaning: MockWord {
        MockWord(
            index: -7,
            context: ["成語"],
            meanings: [
                "to add flowers to brocade; to make something already good even better by adding further refinement or excellence"
            ],
            pinyin: "jǐn shàng tiān huā",
            simplified: "锦上添花",
            traditional: "錦上添花",
            zhuyin: "ㄐㄧㄣˇ ㄕㄤˋ ㄊㄧㄢ ㄏㄨㄚ",
            characters: "錦上添花",
            phonetic: "ㄐㄧㄣˇ ㄕㄤˋ ㄊㄧㄢ ㄏㄨㄚ"
        )
    }
}
