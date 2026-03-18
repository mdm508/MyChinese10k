//
//  WordIndex+CoreDataProperties.swift
//  CoreDataModels
//
//  Created by Matthew McLaughlin on 3/17/26.
//
//

public import Foundation
public import CoreData


public typealias WordIndexCoreDataPropertiesSet = NSSet

extension WordIndex {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WordIndex> {
        return NSFetchRequest<WordIndex>(entityName: "WordIndex")
    }

    @NSManaged public var current: Int64
    @NSManaged public var lastModified: Date?

}

extension WordIndex : Identifiable {

}
