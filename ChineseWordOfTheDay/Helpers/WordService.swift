//
//  WordService.swift
//  ChineseWordOfTheDay
//
//  Created by the assistant on 12/12/25.
//

import Foundation
import CoreData
import CloudKit
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

    /// Marks the given word as "seen" by updating status in Core Data and synchronizing with CloudKit.
    ///
    /// - Parameters:
    ///   - word: The `Word` entity to mark as seen.
    ///
    /// This method attempts to push the updated state to CloudKit with a timeout to avoid hanging the app.
    /// It always attempts to save changes to Core Data regardless of CloudKit outcome.
    @discardableResult
    func markWordAsSeen(_ word: Word) async -> Bool {
        // Attempt to update CloudKit with a timeout, but never block local save
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await createCloudKitRecord(for: word)
                }
                group.addTask {
                    try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                    throw NSError(domain: "Timeout", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit operation timed out"])
                }
                try await group.next()
                group.cancelAll()
            }
        } catch {
            // Handle CloudKit errors gracefully, but proceed with Core Data save
            print("⚠️ CloudKit operation failed or timed out: \(error)")
        }
        // Always save the local Core Data state
        do {
            try context.save()
            print("✅ Successfully saved word status locally")
            return true
        } catch {
            print("❌ Error saving changes: \(error)")
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
    /// Creates a CloudKit record for a seen word. This should be implemented to match your CloudKit schema.
    ///
    /// - Parameter word: The `Word` entity to sync to CloudKit.
    /// - Throws: Any errors thrown by CloudKit.
    private func createCloudKitRecord(for word: Word) async throws {
        // Placeholder: Implement your actual CloudKit sync logic here.
        // This is a stub for demonstration and should be replaced with real CloudKit code.
        print("[Stub] Would create CloudKit record for word: \(word)")
    }
    
    // You can add additional methods for deleting, fetching, or synchronizing words and indices as needed.
}
