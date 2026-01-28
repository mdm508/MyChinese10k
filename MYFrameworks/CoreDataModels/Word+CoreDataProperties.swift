//
//  Word+CoreDataProperties.swift
//  WordFramework
//
//  Created by m on 7/11/23.
//
//

import Foundation
import CoreData

extension Word: Identifiable {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<Word> {
        return NSFetchRequest<Word>(entityName: "Word")
    }
    @NSManaged public var context: [String]
    @NSManaged public var index: Int64
    @NSManaged public var meanings: [String]
    @NSManaged public var pinyin: String
    @NSManaged public var simplified: String
    @NSManaged public var traditional: String
    @NSManaged public var zhuyin: String
}

extension Word: WordRepresentable {
    /// Fetch the characters according to the user's preference.
    public var characters: String {
        let ws = (UserPreferences.get(.chineseWritingSystem))
        if ws == .simplified {
            return self.simplified
        } else if ws == .traditional {
            return self.traditional
        } else {
            print("Warning: Invalid writting system. Defaulting to traditional")
            return self.traditional
        }
    }
    /// Fetch phonetic notation according to the user's preference.
    public var phonetic: String {
        let ws = (UserPreferences.get(.phoneticNotation))
        if ws == .pinyin {
            return self.pinyin
        } else if ws == .zhuyin {
            return self.zhuyin
        } else {
            print("Warning: Invalid phonetic notation. Defaulting to zhuyin")
            return self.zhuyin
        }
    }
}
