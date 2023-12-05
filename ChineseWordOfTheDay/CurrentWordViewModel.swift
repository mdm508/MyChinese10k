//
//  CurrentWordViewModel.swift
//  ChineseWordOfTheDay
//
//  Created by m on 10/28/23.
//

import SwiftUI
import CoreData
import CloudKit

class WordViewModel: ObservableObject {
    @Published var currentWord: Word = Word()
    let context: NSManagedObjectContext
    init(viewContext: NSManagedObjectContext) {
        self.context = viewContext
        self.setCurrentWord()
    }
}

extension WordViewModel {
    /// Called whenever you want to push a new word to the cloud database
    func addNewWordStatusToICloud(withStatus newStatus: Int64){
        let wordStatus = WordStatus(context: context)
        wordStatus.traditional = self.currentWord.traditional
        wordStatus.status = newStatus
        saveChanges()
    }
    /// the current word is added to icloud with the given status. also updates local word status
    /// TODO: Better name and maybe separate out into a different function
    func updateCurrentWordStatus(newStatus: Int64) {
        addNewWordStatusToICloud(withStatus: newStatus)
        self.currentWord.status = newStatus
        saveChanges()
        setCurrentWord()
    }
    /// Retrieve a single word with `status` and with higest `Word.spokenFrequency`
    func fetchWordWithStatus(status: Int64) -> Word? {
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        request.predicate = NSPredicate(format: "status == %d", status)
        request.fetchLimit = 1
        do {
            return try self.context.fetch(request).first
        } catch {
            print("Error fetching word: \(error)")
            return nil
        }
    }
    /// Fetches current word and publishes changes via `self.currentWord`
    func setCurrentWord() {
        if let word = fetchWordWithStatus(status: 0) {
            self.currentWord = word
        }
    }
    /// conveinence function for saving changes
    func saveChanges() {
        do {
            try context.save()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}

extension WordViewModel: CurrentWordRefreshDelegate {
    /// Called whenever a local status update occured. Current word may have changed so this re-fetches the lowest status.
    func refresh() {
        setCurrentWord()
    }
}
    
extension WordViewModel {
    /// - Warning: Will reset all local statuses in the database with status 1 back to zero
    /// Only used for testing
    func resetAllStatus(){
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        request.predicate = NSPredicate(format: "status == %d", 1)
        let words = try? self.context.fetch(request)
        if let words = words {
            for w in words {
                w.status = 0
            }
            saveChanges()
            setCurrentWord()
        }
    }
}
