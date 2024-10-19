//
//  WordRepresentable.swift
//  ChineseWordOfTheDay
//
//  Created by m on 10/3/24.
//

import Foundation

protocol WordRepresentable {
    var context: String { get }
    var frequency: Int64 { get }
    var index: Int64 { get }
    var level: Double { get }
    var meanings: [String] { get }
    var pinyin: String { get }
    var simplified: String { get }
    var spokenFrequency: Int64 { get }
    var traditional: String { get }
    var writtenFrequency: Int64 { get }
    var zhuyin: String { get }
    var synonyms: [String] { get }
    var status: Int64 { get }
}

extension Word: WordRepresentable {
    
}
