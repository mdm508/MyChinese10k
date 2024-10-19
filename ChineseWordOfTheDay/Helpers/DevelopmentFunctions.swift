//
//  DevelopmentFunctions.swift
//  ChineseWordOfTheDay
//
//  Created by m on 12/14/23.
//

import Foundation
import CloudKit
import CoreData

/// - Warning: Will reset all local statuses in the database with status 1 back to zero
/// Only used for testing
func resetAllLocalStatus(){
    let context = PersistenceController.shared.context
    let request: NSFetchRequest<Word> = Word.fetchRequest()
    request.predicate = NSPredicate(value: true)
    let words = try? context.fetch(request)
    if let words = words {
        for w in words {
            w.status = LearnStatus.unseen.rawValue
        }
        try! context.save()
    }
}

/// - Warning: Will delete everything in iCloud
func deletAllCloudWordStatus() async {
    let db = Cloud.db
    let records = try! await db.records(matching: CKQuery(recordType: Cloud.wordStatusRecordType, predicate: NSPredicate(value: true)), inZoneWith: Cloud.wordStatusRecordZone.zoneID, desiredKeys: nil)
    let matches = records.matchResults
    let recordIds = matches.map{recordTuple in recordTuple.0}
    print(recordIds.count)
    print(recordIds)
    let operation = CKModifyRecordsOperation(recordsToSave: nil, recordIDsToDelete: recordIds)
    operation.modifyRecordsResultBlock = { (result: Result<Void, Error>) in
        switch result {
        case .success:
            // Handle success
            print("deleted recorcds")
        case .failure(let error):
            // Handle failure
            print("Error modifying records: \(error)")
        }
    }
        db.add(operation)
}

