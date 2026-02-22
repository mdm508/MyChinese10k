//
//  Word+CoreDataProperties.swift
//  WordFramework
//
//  Created by m on 7/11/23.
//
//

import Foundation
import CoreData

extension Word: Identifiable, WordRepresentable {
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
    @NSManaged public var characters: String
    @NSManaged public var phonetic: String
}

