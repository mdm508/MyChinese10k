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
    /// Retrieve a single word with `status` and with higest `Word.spokenFrequency`
    static func fetchWordWithStatus(context: NSManagedObjectContext, status: Int64) -> Word? {
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
    /// return
    static func fetchHigestPriorityUnseenWord(context: NSManagedObjectContext) -> Word? {
        ///Constructs a compound predicate that filters out all the words on the iCloud
        ///Return value of nil indicates there are no word statuses that we need to filter
        func constructPredicate() -> NSCompoundPredicate? {
            //get all the words from icloud != to status 1
            if let s = WordStatus.fetchSeenAndKnown(context: context){
                let traditionalArray = s.compactMap{wordStatus in wordStatus.traditional}
                let orPredicate = NSCompoundPredicate(orPredicateWithSubpredicates: traditionalArray.map{NSPredicate(format: "traditional == %@", $0)})
                return NSCompoundPredicate(notPredicateWithSubpredicate: orPredicate)
            }
            return nil
        }
        ///YO you need to write a predicate here that also considers the status
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

///// Purpose is to fetch in pages of words and do a new fetch when needed
//struct WordFetcher {
//    static let batchSize = 10
//    private let context: NSManagedObjectContext
//    var fetchedWords: [Word] = []
//    init(context: NSManagedObjectContext){
//        self.context = context
//        fetch()
//       
//    }
//}
//extension WordFetcher {
//    private mutating func fetch(){
//        if let words = Word.fetchHigestPriorityUnseenWords(context: self.context, batchSize: Self.batchSize){
//            self.fetchedWords = words.reversed()
//        }
//    }
//    /// A return value of nil indicates the user has learned everything
//    public mutating func getCurrentWord() -> Word? {
//        if fetchedWords.count > 0 {
//            return fetchedWords.popLast()
//        }
//        fetch()
//        return fetchedWords.popLast()
//    }
//}
