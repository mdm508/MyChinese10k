//
//  StringArrayTransformer.swift
//  CoreDataModels
//
//  Created by Matthew McLaughlin on 3/27/26.
//


import Foundation

@objc(StringArrayTransformer)
public final class StringArrayTransformer: NSSecureUnarchiveFromDataTransformer {
    static let name = NSValueTransformerName(rawValue: "StringArrayTransformer")

    override public static var allowedTopLevelClasses: [AnyClass] {
        return [NSArray.self, NSString.self]
    }

    public static func register() {
        let transformer = StringArrayTransformer()
        ValueTransformer.setValueTransformer(transformer, forName: name)
    }
}
