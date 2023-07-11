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
public class Word: NSManagedObject, Codable {

    
    var context: String {
        my_context
    }

    var frequency: Int16 {
        my_frequency
    }

    var index: Int32 {
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

    var spokenFrequency: Int16 {
        my_spokenFrequency
    }

    var traditional: String {
        my_traditional
    }

    var writtenFrequency: Int16 {
        my_writtenFrequency
    }

    var zhuyin: String {
        my_zhuyin
    }
    
    public required convenience init(from decoder: Decoder) throws {

//        guard let entity = NSEntityDescription.entity(forEntityName: "Word", in: context) else {
//            fatalError("unable to find entidy Word")
//        }
        guard let bundle = Bundle(identifier: "matthedm.WordFramework") else {
            fatalError("could't locate bundle")
        }
        guard let model = NSManagedObjectModel.mergedModel(from: [bundle]) else {
            fatalError("couldn't find model")
        }
        guard let entity = model.entitiesByName["Word"] else {
            fatalError("Unable to find entity 'Word'")
        }

        
//        guard let codingUserInfoContextKey = CodingUserInfoKey(rawValue: "context"),
//              let context = decoder.userInfo[codingUserInfoContextKey] as? NSManagedObjectContext,
//              let entity = NSEntityDescription.entity(forEntityName: "Word", in: context) else {
//            fatalError("Failed to decodeWord")
//        }
        
        self.init(entity: entity, insertInto: nil)

        let container = try decoder.container(keyedBy: CodingKeys.self)
        my_index = try container.decode(Int32.self, forKey: .index)
        my_spokenFrequency = try container.decode(Int16.self, forKey: .spokenFrequency)
        my_writtenFrequency = try container.decode(Int16.self, forKey: .writtenFrequency)
        my_context = try container.decode(String.self, forKey: .context)
        my_meanings = try container.decode([String].self, forKey: .meanings)
        my_level = try container.decode(Double.self, forKey: .level)
        my_pinyin = try container.decodeIfPresent(String.self, forKey: .pinyin)
        my_simplified = try container.decodeIfPresent(String.self, forKey: .simplified)
        my_zhuyin = try container.decode(String.self, forKey: .zhuyin)
        my_frequency = try container.decode(Int16.self, forKey: .frequency)
        my_traditional = try container.decode(String.self, forKey: .traditional)
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(my_index, forKey: .index)
        try container.encode(my_spokenFrequency, forKey: .spokenFrequency)
        try container.encode(my_writtenFrequency, forKey: .writtenFrequency)
        try container.encodeIfPresent(my_context, forKey: .context)
        try container.encodeIfPresent(my_meanings, forKey: .meanings)
        try container.encode(my_level, forKey: .level)
        try container.encodeIfPresent(my_pinyin, forKey: .pinyin)
        try container.encodeIfPresent(my_simplified, forKey: .simplified)
        try container.encodeIfPresent(my_zhuyin, forKey: .zhuyin)
        try container.encode(my_frequency, forKey: .frequency)
        try container.encodeIfPresent(my_traditional, forKey: .traditional)
    }
    private enum CodingKeys: String, CodingKey {
        case index
        case traditional
        case zhuyin
        case simplified
        case pinyin
        case level
        case meanings
        case context
        case writtenFrequency
        case spokenFrequency
        case frequency
    }
}



