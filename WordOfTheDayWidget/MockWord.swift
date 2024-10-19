//
//  MockWord.swift
//  ChineseWordOfTheDay
//
//  Created by m on 10/3/24.
//

import Foundation

// Define a struct that mirrors the Word entity
struct MockWord: Identifiable, WordRepresentable{
    var id = UUID()
    var context: String
    var frequency: Int64
    var index: Int64
    var level: Double
    var meanings: [String]
    var pinyin: String
    var simplified: String
    var spokenFrequency: Int64
    var traditional: String
    var writtenFrequency: Int64
    var zhuyin: String
    var synonyms: [String]
    var status: Int64

    // Static placeholder word with realistic data
    static let placeholder = MockWord(
        context: "教育", // Education
        frequency: 980,
        index: 1500,
        level: 2.0,
        meanings: ["to study", "to learn"],
        pinyin: "xuéxí",
        simplified: "学习",
        spokenFrequency: 970,
        traditional: "學習",
        writtenFrequency: 960,
        zhuyin: "ㄒㄩㄝˊ ㄒㄧˊ",
        synonyms: ["研习", "进修"],
        status: 1
    )
}
