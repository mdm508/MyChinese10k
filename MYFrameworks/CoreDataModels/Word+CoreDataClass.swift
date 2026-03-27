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
public class Word: NSManagedObject, @unchecked Sendable {
    /// Returns the index of the word with the largest index.
    public static func maxIndex(context: NSManagedObjectContext) -> Int64? {
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "index", ascending: false)]
        request.fetchLimit = 1
        do {
            let maxIndex = try context.fetch(request).first?.index
            return maxIndex
        } catch {
            print("Failded to fetch the largest index for some reason")
            return nil
        }
    }
    public static func fetchWord(at index: Int64, context: NSManagedObjectContext) -> Word? {
        let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "index == %d", index)
        fetchRequest.fetchLimit = 1 // Ensure only one result is returned
        do {
            return try context.fetch(fetchRequest).first
        } catch {
            print("Failed to fetch Word at index \(index): \(error)")
            return nil
        }
    }
    public static func fetchSeenAndKnown(context: NSManagedObjectContext) -> [Word]? {
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        request.predicate = NSPredicate(format: "status IN %@", [LearnStatus.seen.rawValue, LearnStatus.known.rawValue])
        do {
            return try context.fetch(request)
        } catch {
            print("Error fetching WordStatus: \(error)")
            return nil
        }
    }
    
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
}

