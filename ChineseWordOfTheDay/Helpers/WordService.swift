//
//  WordService.swift
//  ChineseWordOfTheDay
//
//  Created by the assistant on 12/12/25.
//

import Foundation
import CoreData
import CoreDataModels
import Persistence
import Combine
import WidgetKit

/// `WordService` centralizes all operations and business logic concerning `Word` and `WordIndex` Core Data entities.
///  It is basically a helper that acts as an intermediary between views and Core Data.
///
/// - Responsibilities:
///   - Notify observers whenever the index changes.
///   - Encapsulates all direct interactions with Core Data for `Word` and `WordIndex`.
///   - Provides convenience methods for updating, saving, or synchronizing `Word` and `WordIndex` data.
///   - Listen for remote changes from CloudkitStore. Refetch whenever such changes occur.

final class WordService: ObservableObject{
    /// The managed object context used for all local Core Data operations.
    private let context: NSManagedObjectContext
    @Published var currentIndex: Int64!
    @Published var currentWord: Word!
    private var cancellables: Set<AnyCancellable> = []
    
    /// One more than the largest index in the database.
    var maxIndex: Int64 {
        Word.maxIndex(context: context)! + 1
    }
    /// Initializes the service with a given managed object context.
    /// - Parameter context: The Core Data managed object context to use for all data operations.
    init(context: NSManagedObjectContext) {
        self.context = context
        self.fetchAndSetCurrentWordAndIndex()
        /// Set up subscribtion to persistent history changes
        NotificationCenter.default.publisher(for: .cdcksStoreDidChange)
            .receive(on: DispatchQueue.main)
            .sink{ [weak self] _ in
                self?.fetchAndSetCurrentWordAndIndex()
            }
            .store(in: &cancellables)
    }
    /// Marks the given word as seen by upserting a WordStatus (status = 1) and incrementing the WordIndex, then saving.
    @discardableResult
    func markWordAsSeen() -> Bool {
        do {
            try upsertWordStatus(for: self.currentWord, to: .seen)
            try incrementCurrentWordIndex()
            try context.save()
            //update obserervers of change
            fetchAndSetCurrentWordAndIndex()
            return true
        } catch {
            print("❌ Error updating status or index: \(error)")
            return false
        }
    }
    /// Calling this method will fetch the current index and word then notify observers if either value changed.
    /// Note: - This method is the only method that will ever modify either of the observed properties. This is to make
    /// debugging easier since we have a centralized location where the published properties are updated. The only
    /// cost is just the fact that we need to do more fetches than we would otherwise.
    private func fetchAndSetCurrentWordAndIndex(){
        self.currentIndex = self.fetchCurrentIndex()
        self.currentWord = self.fetchCurrentWord()
        self.syncWidget()
    }
    /// Loads the current word by fetching the current WordIndex
    /// Ensures the fetched word has the appropriate phonetic and character set based on the current settings.
    private func fetchCurrentWord() -> Word {
        
        if let fetchedWord = Word.fetchWord(at: self.currentIndex, context: self.context){
            self.setCharacterAndPhonetics(for: fetchedWord)
            return fetchedWord
        } else {
            fatalError("Unable to fetch word at \(self.fetchCurrentIndex())")
        }
    }
    /// Fetch the current WordIndex. If none exists then we assume it is the first time you loaded the app and set the index to 1.
    private func fetchCurrentIndex() -> Int64 {
        do {
            let request: NSFetchRequest<WordIndex> = WordIndex.fetchRequest()
            request.fetchLimit = 1
            if let existing = try context.fetch(request).first {
                return existing.current
            } else {
                // Only called first time app created
                let indexObject = WordIndex(context: context)
                indexObject.current = 1
                indexObject.lastModified = Date()
                try context.save()
                return 1
            }
        } catch {
            fatalError("Failed to fetch or create WordIndex: \(error)")
        }
    }
    // MARK: - Update Methods
    /// Update Word Status for `word`
    private func upsertWordStatus(for word: Word, to status: LearnStatus) throws {
        let request: NSFetchRequest<WordStatus> = WordStatus.fetchRequest()
        request.predicate = NSPredicate(format: "traditional == %@", word.traditional)
        request.fetchLimit = 1

        let wordStatus: WordStatus
        if let existing = try context.fetch(request).first {
            wordStatus = existing
        } else {
            let newStatus = WordStatus(context: context)
            newStatus.traditional = word.traditional
            wordStatus = newStatus
        }
        wordStatus.status = status.rawValue
        wordStatus.lastModified = Date()
    }
    private func getOrCreateWordIndex() throws -> WordIndex {
        let request: NSFetchRequest<WordIndex> = WordIndex.fetchRequest()
        request.fetchLimit = 1
        if let existing = try context.fetch(request).first {
            return existing
        } else {
            let index = WordIndex(context: context)
            index.current = 0
            return index
        }
    }
    private func incrementCurrentWordIndex() throws {
        let wordIndex = try getOrCreateWordIndex()
        wordIndex.current += 1
        wordIndex.lastModified = Date()
    }
}


extension WordService{
    /// Call this method when the settings have changed to ensure that phonetic and zhuyin stay up to date in WordDetail
    public func settingsUpdated(){
        self.fetchAndSetCurrentWordAndIndex()
    }
    /// Fills the given word's `characters` and `phonetic` fields with the appropriate values based off the current settings.
    public func setCharacterAndPhonetics(for word: Word) {
        let characters = self.fetchCharactersBasedOnSetting(for: word)
        word.characters = characters
        let phonetic = self.fetchPhoneticBasedOnSetting(for: word)
        word.phonetic = phonetic
    }
    /// Fetch the character set (simplified or traditional) based on the user's current preferenc)
    private func fetchCharactersBasedOnSetting(for word: Word) -> String {
        let ws = (UserPreferences.get(.chineseWritingSystem))
        if ws == .simplified {
            return word.simplified
        } else if ws == .traditional {
            return word.traditional
        } else {
            print("Warning: Invalid writting system. Defaulting to traditional")
            return word.traditional
        }
    }
    /// Fetch phonetic notation (zhuyin or pinyin) according to the user's preference.
    private func fetchPhoneticBasedOnSetting(for word:Word) -> String {
        let ws = (UserPreferences.get(.phoneticNotation))
        if ws == .pinyin {
            return word.pinyin
        } else if ws == .zhuyin {
            return word.zhuyin
        } else {
            print("Warning: Invalid phonetic notation. Defaulting to zhuyin")
            return word.zhuyin
        }
    }
    /// Ensures the current word is written out to UserDefaults and the timeline is reloaded.
    private func syncWidget(){
        self.currentWord.writeToUserDefaults()
        WidgetCenter.shared.reloadAllTimelines()
    }
}
