//
//  Word+CoreDataClass.swift
//  ChineseWordOfTheDay
//
//  Created by m on 6/30/23.
//
//

import Foundation
import CoreData


@objc(Word)
public class Word: NSManagedObject {
    /// - Parameters:
    ///   - context:
    ///   - status:
    /// - Returns: The highest frequency `Word` with the given `status`
    public static func fetchWordWithStatus(context: NSManagedObjectContext, status: Int64) -> Word? {
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        request.predicate = NSPredicate(format: "status == %d", status)
        request.fetchLimit = 1
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching word: \(error)")
            return nil
        }
    }
    ///  Determines the highest priority `Word` by filtering out any `Word` with a
    ///  `WordStatus` entry in iCloud. Just the fact of a `WordStatus` existing on the cloud.
    ///   indicates that the `Word` has already been seen.
    /// - Parameter context:
    /// - Returns: Highest priority unseen `Word`.
    public static func fetchHigestPriorityUnseenWord(context: NSManagedObjectContext) -> Word? {
        /// Constructs a compound predicate that filters out all the words on the iCloud.
        /// - Note: Return value of `nil` indicates there are no word statuses that we need to filter
        func constructPredicate() -> NSCompoundPredicate? {
            if let s = WordStatus.fetchSeenAndKnown(context: context){
                let traditionalArray = s.compactMap{wordStatus in wordStatus.traditional}
                let orPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: traditionalArray.map{NSPredicate(format: "traditional == %@", $0)})
                return NSCompoundPredicate(notPredicateWithSubpredicate: orPredicate)
            }
            return nil
        }
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        request.predicate = constructPredicate()
        request.sortDescriptors = [NSSortDescriptor(key: #keyPath(WordStatus.status), ascending: false)]
        request.fetchLimit = 1
        do {
            return try context.fetch(request).first
        } catch {
            print("Error fetching word: \(error)")
            return nil
        }
    }
}
