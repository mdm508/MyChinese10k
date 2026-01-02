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

/// `WordService` centralizes all operations and business logic concerning `Word` and `WordIndex` Core Data entities.
///
/// - Responsibilities:
///   - Encapsulates all direct interactions with Core Data for `Word` and `WordIndex`.
///   - Optionally synchronizes changes to CloudKit (if needed).
///   - Provides convenience methods for updating, saving, or synchronizing `Word` and `WordIndex` data.
///
/// This service should be injected into higher-level managers or view models, which then use its methods rather than manipulating Core Data directly.
final class WordService {
    /// The managed object context used for all local Core Data operations.
    private let context: NSManagedObjectContext

    /// Initializes the service with a given managed object context.
    /// - Parameter context: The Core Data managed object context to use for all data operations.
    init(context: NSManagedObjectContext) {
        self.context = context
    }

    /// Marks the given word as seen by upserting a WordStatus (status = 1) and incrementing the WordIndex, then saving.
    @discardableResult
    func markWordAsSeen(_ word: Word) async -> Bool {
        do {
            try upsertWordStatus(for: word, to: .seen)
            try incrementCurrentWordIndex()
            try context.save()
            return true
        } catch {
            print("❌ Error updating status or index: \(error)")
            return false
        }
    }

    /// Increments the given `WordIndex`'s current value and saves the change to Core Data.
    ///
    /// - Parameter wordIndex: The `WordIndex` entity to increment.
    /// - Throws: Any error thrown by Core Data's save operation.
    func incrementWordIndex(_ wordIndex: WordIndex) throws {
        wordIndex.current += 1
        try context.save()
    }

    // MARK: - Private Helpers
    // You can add additional methods for deleting, fetching, or synchronizing words and indices as needed.

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
    }
}
