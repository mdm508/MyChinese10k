//
//  WordStatus+CoreDataClass.swift
//  WordFramework
//
//  Created by m on 12/11/23.
//
//

import Foundation
import CoreData

@objc(WordStatus)
public class WordStatus: NSManagedObject {
    /// returns an array of WordStatuses who have a learn status of  either `LearnStatus.known` or `LearnStatus.seen`
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
