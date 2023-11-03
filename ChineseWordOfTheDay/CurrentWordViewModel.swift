//
//  CurrentWordViewModel.swift
//  ChineseWordOfTheDay
//
//  Created by m on 10/28/23.
//

import SwiftUI
import CoreData


class WordViewModel: ObservableObject {
    @Published var currentWord: Word = Word()
    let context: NSManagedObjectContext
    init(viewContext: NSManagedObjectContext) {
        self.context = viewContext
        self.setCurrentWord()
    }
}

extension WordViewModel {
    func updateCurrentWordStatus(newStatus: Int64) {
        self.currentWord.status = newStatus
        saveChanges()
        setCurrentWord()
    }
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
    func setCurrentWord() {
        if let word = fetchWordWithStatus(status: 0) {
            self.currentWord = word
        }
    }
    func saveChanges() {
        do {
            try context.save()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
}

