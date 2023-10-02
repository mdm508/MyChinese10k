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
    public var context: String {
        my_context
    }

    public var frequency: Int64 {
        my_frequency
    }

    public var index: Int64{
        my_index
    }

    public var level: Double {
        my_level
    }

    private var meanings: [String] {
        my_meanings
    }

    public var pinyin: String {
        my_pinyin
    }

    public var simplified: String {
        my_simplified
    }

    public var spokenFrequency: Int64 {
        my_spokenFrequency
    }

    public var traditional: String {
        my_traditional
    }

    public var writtenFrequency: Int64 {
        my_writtenFrequency
    }

    public var zhuyin: String {
        my_zhuyin
    }
    public var synonyms: [String] {
        my_synonyms
    }
}



