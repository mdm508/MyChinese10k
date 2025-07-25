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
    public var id = UUID()


    // Static placeholder word with realistic data
    public static var placeholder: MockWord {
        MockWord(
            index: -1,
            context: ["教育"], // Education
            meanings: ["to study", "to learn"],
            pinyin: "xuéxí",
            simplified: "学习",
            traditional: "學習",
            zhuyin: "ㄒㄩㄝˊ ㄒㄧˊ")
    }
}
extension MockWord: Encodable, Decodable {
    /// Decodes MockWord from UserDefaults.
    /// Use to share data between main application and widget.
    /// - Parameters:
    ///   - appGroupId:
    ///   - mockWordKey:
    /// - Returns: Most recent word return to `UserDefaults`.
    /// - Precondition: `appGroupId` exists and both the widget and main app are a part of it.
        public static func readFromUserDefaults(appGroupId: String, mockWordKey: String) -> MockWord? {
            let sharedDefaults = UserDefaults(suiteName: appGroupId)
            if let savedData = sharedDefaults?.data(forKey: mockWordKey),
               let decodedWord = try? JSONDecoder().decode(MockWord.self, from: savedData) {
                return decodedWord
            }
            return nil
        }
}
