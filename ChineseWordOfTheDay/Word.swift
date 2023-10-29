//
//  Word.swift
//  WordFramework
//
//  Created by m on 10/28/23.
//
//

import Foundation
import SwiftData


@Model public class Word {
    var context: String?
    var frequency: Int64 = 0
    var index: Int64 = 0
    var level: Double = 0.0
    @Attribute(.transformable(by: "NSSecureUnarchiveFromData")) var meanings: [String]?
    var pinyin: String?
    var simplified: String?
    var spokenFrequency: Int64 = 0
    @Attribute(.transformable(by: "NSSecureUnarchiveFromData")) var synonyms: [String]?
    var traditional: String?
    var version: Int64 = 0
    var writtenFrequency: Int64 = 0
    var zhuyin: String?
    var statusNumber: Int64? = 0
    

    public init() { }
    

#warning("Index on Word:index is unsupported in SwiftData.")
#warning("Index on Word:traditional is unsupported in SwiftData.")

}
