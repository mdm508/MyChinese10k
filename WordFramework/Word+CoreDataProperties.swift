//
//  Word+CoreDataProperties.swift
//  WordFramework
//
//  Created by m on 7/11/23.
//
//

import Foundation
import CoreData


extension Word {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Word> {
        return NSFetchRequest<Word>(entityName: "Word")
    }

    @NSManaged public var context: String
    @NSManaged public var frequency: Int64
    @NSManaged public var index: Int64
    @NSManaged public var level: Double
    @NSManaged public var meanings: [String]
    @NSManaged public var pinyin: String
    @NSManaged public var simplified: String
    @NSManaged public var spokenFrequency: Int64
    @NSManaged public var traditional: String
    @NSManaged public var writtenFrequency: Int64
    @NSManaged public var zhuyin: String
    @NSManaged public var synonyms: [String]
    @NSManaged public var status: Int64

}

extension Word : Identifiable {

}
