//
//  WordRepresentable.swift
//  ChineseWordOfTheDay
//
//  Created by m on 10/3/24.
//

import Foundation
import Combine

public protocol WordRepresentable {
    var context: [String] { get }
    var index: Int64 { get }
    var meanings: [String] { get }
    var pinyin: String { get }
    var simplified: String { get }
    var traditional: String { get }
    var zhuyin: String { get }
    var characters: String { get}
    var phonetic: String { get}
}

public extension WordRepresentable {
    func cleanedMeanings() -> [String] {
        var result: [String] = []

        for meaning in self.meanings {
            let pieces = meaning
                .split(separator: ";")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                // Remove text in parentheses: "to go (somewhere)" -> "to go"
                .map { $0.replacingOccurrences(of: #"\s*\([^)]*\)"#, with: "", options: .regularExpression) }
                .filter { !$0.isEmpty }
                // Your 20-character limit
                .filter { $0.count <= 20 }

            result.append(contentsOf: pieces)
        }

        return result
    }
}
