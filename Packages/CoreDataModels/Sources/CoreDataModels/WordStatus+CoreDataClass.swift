//
//  WordStatus+CoreDataClass.swift
//  CoreDataModels
//
//  Created by Matthew McLaughlin on 4/3/26.
//
//
import Foundation
import CoreData

public typealias WordStatusCoreDataClassSet = NSSet
@objc(WordStatus)
public class WordStatus: NSManagedObject {
    /// Retrieve all `WordStatus` that have a `LearnStatus` of either `.seen` or `.known`
    /// - Parameter context:
    /// - Returns: Array of `.known` and `.seen` `WordStatus`
    public static func fetchSeenAndKnown(context: NSManagedObjectContext) -> [WordStatus]? {
        let request: NSFetchRequest<WordStatus> = WordStatus.fetchRequest()
        request.predicate = NSPredicate(format: "status IN %@", [LearnStatus.seen.rawValue, LearnStatus.known.rawValue])
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching WordStatus: \(error)")
            return nil
        }
    }
}
