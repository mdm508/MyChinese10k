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
    /// `characters` and `phonetic` are set to `simplified` or `traditional`, `pinyin` or `zhuyin` resp.
    /// depending on the current settings. These are the only two properties defined on `Word` that actually might change.
}

extension Word {
    /// Used when the user want's to share the current word of the day.
    public var shareText: String {
        return """
            Word of the day: \(self.characters) \(self.phonetic)
            """
    }
}

extension Word: WordRepresentable {
    // These replace the @NSManaged versions entirely
    public var characters: String {
        let ws = UserPreferences.get(.chineseWritingSystem)
        return ws == .simplified ? self.simplified : self.traditional
    }

    public var phonetic: String {
        let notation = UserPreferences.get(.phoneticNotation)
        return notation == .pinyin ? self.pinyin : self.zhuyin
    }
}
