//
//  Persistence+De-Duplication.swift
//  ChineseWordOfTheDay
//
//  Created by m on 12/30/23.
//

import Foundation
import CoreData

extension PersistenceController {
    func deduplicateWordStatusesAndWait(statusObjectIDs: [NSManagedObjectID]) {
        let taskContext = self.container.newTaskContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        taskContext.performAndWait {
            statusObjectIDs.forEach { statusObjectID in
                deduplicateWordStatus(statusObjectID: statusObjectID, performingContext: taskContext)
            }
            do {
                try taskContext.save()
            } catch {
                print("Error saving context: \(error)")
            }
        }
    }
    private func deduplicateWordStatus(statusObjectID: NSManagedObjectID, performingContext: NSManagedObjectContext) {
        guard let wordStatus = performingContext.object(with: statusObjectID) as? WordStatus,
              let traditional = wordStatus.traditional else {
            print("\(#function): Unable to fetch WordStatus for ID: \(statusObjectID)")
            return
        }
        let fetchRequest: NSFetchRequest<WordStatus> = WordStatus.fetchRequest()
        fetchRequest.predicate = NSPredicate(format: "traditional == %@", traditional)
        
        guard var duplicatedWordStatuses = try? performingContext.fetch(fetchRequest), !duplicatedWordStatuses.isEmpty else {
            return
        }
        let latestEntry = duplicatedWordStatuses.max(by: { ($0.lastModified ?? Date()) < ($1.lastModified ?? Date()) })
        if let latestEntry = latestEntry {
            //kick out latest entry
            duplicatedWordStatuses.removeAll(where: { $0 == latestEntry })
            remove(duplicatedWordStatuses: duplicatedWordStatuses, winner: latestEntry, performingContext: performingContext)
        }
    }
}

private func remove(duplicatedWordStatuses: [WordStatus], winner: WordStatus, performingContext: NSManagedObjectContext) {
    duplicatedWordStatuses.forEach { wordStatus in
        performingContext.delete(wordStatus)
        // Perform other actions if needed, such as handling cloud deletions
    }
}

