//
//  StringArrayTransformer.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 4/8/25.
//


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