//
//  CurrentWordViewModel.swift
//  ChineseWordOfTheDay
//
//  Created by m on 10/28/23.
//

import SwiftUI
import CoreData
import CloudKit
import Combine
import WidgetKit

class WordViewModel: ObservableObject {
    @Published private(set) var currentWord: Word?
    let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()
    init(viewContext: NSManagedObjectContext) {
        self.context = viewContext
        self.setCurrentWord()
        NotificationCenter.default.storeDidChangePublisher
            .sink{[weak self] notification in
                self?.refresh()
            }.store(in: &cancellables)
    }
}
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
        WidgetCenter.shared.reloadAllTimelines()
    }
}
extension WordViewModel {
    /// Fetches current word and publishes changes via `self.currentWord`
    private func setCurrentWord() {
        self.currentWord = Word.fetchHigestPriorityUnseenWord(context: self.context)
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
    
