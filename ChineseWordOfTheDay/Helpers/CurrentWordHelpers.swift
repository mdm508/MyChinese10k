////
////  CurrentWordViewModel.swift
////  ChineseWordOfTheDay
////
////  Created by m on 10/28/23.
////
//

import CoreDataModels
import CoreData
import Persistence
import CloudKit

func updateCurrentWordStatusToSeen(word: Word, context: NSManagedObjectContext) async {
    // Create CloudKit record with timeout to prevent hanging
    Task {
        do {
            // Add timeout to prevent hanging
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    try await createCloudKitRecord(for: word)
                }
                
                // Add timeout task
                group.addTask {
                    try await Task.sleep(nanoseconds: 5_000_000_000) // 5 seconds
                    throw NSError(domain: "Timeout", code: -1, userInfo: [NSLocalizedDescriptionKey: "CloudKit operation timed out"])
                }
                
                try await group.next()
                group.cancelAll()
            }
        } catch {
            // Handle specific CloudKit errors
            if let ckError = error as? CKError {
                switch ckError.code {
                case .serverRecordChanged:
                    print("ℹ️ CloudKit record already exists - this is normal for previously seen words")
                case .networkUnavailable, .networkFailure:
                    print("⚠️ CloudKit network error - continuing with local save only")
                case .notAuthenticated:
                    print("⚠️ CloudKit authentication error - continuing with local save only")
                default:
                    print("⚠️ CloudKit error: \(ckError.localizedDescription)")
                }
            } else {
                print("⚠️ CloudKit operation failed or timed out: \(error)")
            }
            // Continue execution even if CloudKit fails
        }
    }
    
    do {
        try context.save()
        print("✅ Successfully saved word status locally")
    } catch {
        print("❌ Error saving changes: \(error)")
    }
}
func incrementWordIndex(wordIndex: WordIndex, context: NSManagedObjectContext) {
    wordIndex.current += 1
    try! context.save()
}

