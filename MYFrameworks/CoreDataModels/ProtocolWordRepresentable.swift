//
//  WordRepresentable.swift
//  ChineseWordOfTheDay
//
//  Created by m on 10/3/24.
//

import Foundation

public protocol WordRepresentable {
    var context: [String] { get }
    var index: Int64 { get }
    var meanings: [String] { get }
    var pinyin: String { get }
    var simplified: String { get }
    var traditional: String { get }
    var zhuyin: String { get }
    var characters: String { get }
    var phonetic: String { get }
}

