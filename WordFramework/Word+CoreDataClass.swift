//
//  Word+CoreDataClass.swift
//  ChineseWordOfTheDay
//
//  Created by m on 6/30/23.
//
//

import Foundation
import CoreData


@objc(Word)
public class Word: NSManagedObject {
    var context: String {
        my_context
    }

    var frequency: Int64 {
        my_frequency
    }

    var index: Int64{
        my_index
    }

    var level: Double {
        my_level
    }

    var meanings: [String] {
        my_meanings
    }

    var pinyin: String {
        my_pinyin ?? ""
    }

    var simplified: String {
        my_simplified ?? ""
    }

    var spokenFrequency: Int64 {
        my_spokenFrequency
    }

    var traditional: String {
        my_traditional
    }

    var writtenFrequency: Int64 {
        my_writtenFrequency
    }

    var zhuyin: String {
        my_zhuyin
    }
}



