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
    @Published private(set) var currentWord: Word = Word()
    @Published private(set) var icloudSyncIsInProgress: Bool = false
    let context: NSManagedObjectContext
    init(viewContext: NSManagedObjectContext) {
        self.context = viewContext
        self.setCurrentWord()
//        self.resetAllStatus()
    }
}
/// public interface
extension WordViewModel {
    func updateCurrentWordStatusToSeen(){
        self.updateCurrentWordStatus(newStatus: LearnStatus.seen.rawValue)
    }
    func startedIcloudSync(){
        self.icloudSyncIsInProgress = true
    }
    // After Icloud Sync is complete set current word
    func finishedIcloudSync(){
        self.icloudSyncIsInProgress = false
        self.setCurrentWord()
    }
}
/// private interface
extension WordViewModel {
    /// Called whenever you want to push a new word to the cloud database
    private func addNewWordStatusToICloud(withStatus newStatus: Int64){
        let wordStatus = WordStatus(context: context)
        wordStatus.traditional = self.currentWord.traditional
        wordStatus.status = newStatus
        wordStatus.lastModified = Date()
        saveChanges()
    }
    /// the current word is added to icloud with the given status. also updates local word status
    /// TODO: Better name and maybe separate out into a different function
    private func updateCurrentWordStatus(newStatus: Int64) {
        addNewWordStatusToICloud(withStatus: newStatus)
        self.currentWord.status = newStatus
        saveChanges()
        setCurrentWord()
    }
    /// Fetches current word and publishes changes via `self.currentWord`
    private func setCurrentWord() {
        if let word = Word.fetchWordWithStatus(context: self.context, status: LearnStatus.unseen.rawValue) {
            self.currentWord = word
        }
    }
    /// conveinence function for saving changes
    private func saveChanges() {
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
}
