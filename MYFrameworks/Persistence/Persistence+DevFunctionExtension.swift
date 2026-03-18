//
//  Persistence+DevFunctionExtension.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 3/18/26.
//

import CloudKit
import CoreData
import CoreDataModels

extension PersistenceController {
    public func deleteAllCloud() {
        deleteAllWordStatus()
        deleteAllWordIndex()
    }
    fileprivate func deleteAllWordStatus() {
        let context = PersistenceController.shared.context
        let request: NSFetchRequest<NSFetchRequestResult> = WordStatus.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        do {
            try context.execute(deleteRequest)
        } catch {
            print("Error executing batch delete for WordStatus: \(error)")
        }
    }
    fileprivate func deleteAllWordIndex() {
        let context = PersistenceController.shared.context
        let request: NSFetchRequest<NSFetchRequestResult> = WordIndex.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: request)
        do {
            try context.execute(deleteRequest)
            // No need to call save() after a batch delete
        } catch {
            print("Error executing batch delete for WordIndex: \(error)")
        }
    }

}
