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

public class StringArrayTransformer: ValueTransformer {
    public override func transformedValue(_ value: Any?) -> Any? {
        return nil
    }

    /**
     The purpose of the reverseTransformedValue method is to deserialize data stored by Core Data into a usable [String] array.
     It ensures that the serialized data, typically stored as Data, is safely converted back into the original format ([String]) for use within the application,
     while adhering to strict type safety and security requirements enforced by modern iOS.
     */
    public override func reverseTransformedValue(_ value: Any?) -> Any? {
        if let data = value as? Data {
            return try? NSKeyedUnarchiver.unarchivedObject(ofClasses: [NSArray.self, NSString.self], from: data) as? [String]
        } else {
            return []
        }
    }



}
