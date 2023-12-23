//
//  CurrentWordViewModel.swift
//  ChineseWordOfTheDay
//
//  Created by m on 10/28/23.
//

import SwiftUI
import CoreData
import CloudKit
import NotificationCenter

class WordViewModel: ObservableObject {
    @Published private(set) var currentWord: Word?
//    private var fetcher: WordFetcher
    let context: NSManagedObjectContext
    init(viewContext: NSManagedObjectContext) {
        self.context = viewContext
//        self.fetcher = WordFetcher(context: self.context)
        self.setCurrentWord()
//        self.resetAllStatus()
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(fetchChanges),
            name: NSNotification.Name(
                rawValue: "NSPersistentStoreRemoteChangeNotification"),
                object: PersistenceController.shared.container.persistentStoreCoordinator
        )
    }
}
/// public interface
extension WordViewModel {
    /// Called whenever you want to push a new word to the cloud database
    func updateCurrentWordStatusToSeen(){
        let wordStatus = WordStatus(context: context)
        if let cur = self.currentWord {
            wordStatus.traditional = cur.traditional
            wordStatus.status =  LearnStatus.seen.rawValue
            wordStatus.lastModified = Date()
        }
        saveChanges()
        setCurrentWord()
    }
}
/// private interface
extension WordViewModel {
    /// Fetches current word and publishes changes via `self.currentWord`
    private func setCurrentWord() {
        self.currentWord = Word.fetchHigestPriorityUnseenWord(context: self.context)
        print(currentWord?.traditional)
    }
    /// conveinence function for saving changes
    private func saveChanges() {
        do {
            try context.save()
        } catch {
            print("Error saving changes: \(error)")
        }
    }
    @objc func fetchChanges(){
//        print("changes")
    }
}

extension WordViewModel: CurrentWordRefreshDelegate {
    /// Called whenever a local status update occured. Current word may have changed so this re-fetches the lowest status.
    func refresh() {
        setCurrentWord()
    }
}
    
