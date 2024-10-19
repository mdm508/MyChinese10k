//
//  WordStatus+CoreDataProperties.swift
//  WordFramework
//
//  Created by m on 12/11/23.
//
//

import Foundation
import CoreData


extension WordStatus {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WordStatus> {
        return NSFetchRequest<WordStatus>(entityName: "WordStatus")
    }
    @NSManaged public var status: Int64
    @NSManaged public var traditional: String?
    @NSManaged public var lastModified: Date?
}

extension WordStatus : Identifiable {

}
