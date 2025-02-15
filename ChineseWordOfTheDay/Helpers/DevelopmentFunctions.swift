//
//  DevelopmentFunctions.swift
//  ChineseWordOfTheDay
//
//  Created by m on 12/14/23.
//

import Foundation
import CloudKit
import CoreData
import WordModels


/// - Warning: Will delete everything in local and cloud
@MainActor
public func deleteAll() {
    Task {
        await deletAllCloudWordStatus()
    }
    deleteAllLocalWordStatus()
    PersistenceController.deleteDatabase()
}

/// - Warning: Will delete everything in iCloud
public func deletAllCloudWordStatus() async {
    let db = Cloud.db
    let records = try! await db.records(
        matching: CKQuery(recordType: Cloud.wordStatusRecordType, predicate: NSPredicate(value: true)),
        inZoneWith: Cloud.wordStatusRecordZone.zoneID,
        desiredKeys: nil
    )
    let matches = records.matchResults
    let recordIds = matches.map { $0.0 }

    let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIds)
    operation.modifyRecordsResultBlock = { result in
        switch result {
        case .success:
            print("Deleted records (this callback may not be on the main thread)")
        case .failure(let error):
            print("Error modifying records: \(error)")
        }
    }

    db.add(operation)
}

@MainActor
fileprivate func deleteAllLocalWordStatus() {
    let context = PersistenceController.shared.context
    let request: NSFetchRequest<NSFetchRequestResult> = WordStatus.fetchRequest()
    let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)

    do {
        try context.execute(deleteRequest)
        // No need to call save() after a batch delete
    } catch {
        print("Error executing batch delete: \(error)")
    }
}
