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

    @NSManaged public var my_context: String
    @NSManaged public var my_frequency: Int16
    @NSManaged public var my_index: Int32
    @NSManaged public var my_level: Double
    @NSManaged public var my_meanings: [String]
    @NSManaged public var my_pinyin: String?
    @NSManaged public var my_simplified: String?
    @NSManaged public var my_spokenFrequency: Int16
    @NSManaged public var my_traditional: String
    @NSManaged public var my_writtenFrequency: Int16
    @NSManaged public var my_zhuyin: String

}

extension Word : Identifiable {

}
