//
//  Persistence+History.swift
//  ChineseWordOfTheDay
//
//  Created by m on 12/30/23.
//

import CoreData
import CloudKit

// MARK: - Notification handlers that trigger history processing.
extension PersistenceController {
    /**
     Handle the container's event changed notifications (NSPersistentCloudKitContainer.eventChangedNotification).
     */
    @objc
    func containerEventChanged(_ notification: Notification) {
         guard let value = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey],
              let event = value as? NSPersistentCloudKitContainer.Event else {
            print("\(#function): Failed to retrieve the container event from notification.userInfo.")
            return
        }
        if event.error != nil {
            print("\(#function): Received a persistent CloudKit container event changed notification.\n\(event)")
        }
    }
}

// MARK: - Process persistent historty asynchronously
extension PersistenceController {
    /**
     Process persistent history, posting any relevant transactions to the current view.
     This method processes the new history since the last history token, and is simply a fetch if there is no new history.
     */
    func processHistoryAsynchronously(for store: NSPersistentStore) {
        historyQueue.addOperation {
            let taskContext = self.container.newTaskContext()
            taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            taskContext.performAndWait {
                self.performHistoryProcessing(performingContext: taskContext, affectedStore: store)
            }
        }
    }
    func widgetProcessHistory() {
        guard let localStore = self.localPersistentStore else {
            print("Local store is not available for widget processing.")
            return
        }
        
        let taskContext = self.container.newTaskContext()
        taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        
        taskContext.performAndWait {
            performHistoryProcessing(performingContext: taskContext, affectedStore: localStore)
        }
    }

    /**
     Fetch history received from outside the app since the last timestamp
    */
    private func performHistoryProcessing(performingContext: NSManagedObjectContext, affectedStore: NSPersistentStore) {
        let lastHistoryToken = historyToken(for: affectedStore)
        let request: NSPersistentHistoryChangeRequest
        if let lastToken = lastHistoryToken {
                // Fetch history after the last known token
                request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastToken)
            } else {
                // No token yet, fetch the entire history available
                request = NSPersistentHistoryChangeRequest.fetchHistory(after: nil as NSPersistentHistoryToken?)

            }
        
        request.affectedStores = [affectedStore]
        let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest!
        historyFetchRequest.predicate = NSPredicate(format: "author != %@", StorageActor.swiftuiApp.rawValue)
        request.fetchRequest = historyFetchRequest

        // Do the fetch
        let result = (try? performingContext.execute(request)) as? NSPersistentHistoryResult
        guard let transactions = result?.result as? [NSPersistentHistoryTransaction] else {
            return
        }
        
        print("\(#function): Processing transactions for store \(affectedStore.identifier ?? "unknown"): \(transactions.count).")
        
        // Skip if there are no transactions to process
        guard !transactions.isEmpty else {
            return
        }
        
        // Update history token for the store
        if let newToken = transactions.last?.token {
            updateHistoryToken(newToken: newToken, for: affectedStore)
        }
        
        // Handle deduplication if necessary (e.g., for "WordStatus" entity)
        deduplicateTransactions(transactions: transactions)
    }


    // MARK: - Deduplication Helper
    private func deduplicateTransactions(transactions: [NSPersistentHistoryTransaction]) {
        var newWordStatusObjectIDs = [NSManagedObjectID]()
        let wordStatusEntityName = WordStatus.entity().name
        // Gather WordStatus IDs for all insertions
        for transaction in transactions where transaction.changes != nil {
            for change in transaction.changes! {
                if change.changedObjectID.entity.name == wordStatusEntityName && change.changeType == .insert {
                    newWordStatusObjectIDs.append(change.changedObjectID)
                }
            }
        }
        // Deduplicate if there are any new insertions
        if !newWordStatusObjectIDs.isEmpty {
            deduplicateWordStatusesAndWait(statusObjectIDs: newWordStatusObjectIDs)
        }
    }

}
extension PersistenceController{
    /**
     Track the last history tokens for the stores.
     The historyQueue reads the token when executing operations, and updates it after completing the processing.
     Access this user default from the history queue.
     */
    func historyToken(for store: NSPersistentStore) -> NSPersistentHistoryToken? {
        // Use a more constant and predictable key for saving/retrieving the token
        let key = store === cloudPersistentStore ? "HistoryTokenCloud" : "HistoryTokenLocal"
        if let data = UserDefaults.standard.data(forKey: key) {
            return try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
        }
        return nil
    }

    func updateHistoryToken(newToken: NSPersistentHistoryToken, for store: NSPersistentStore) {
        // Use the same key for saving the token
        let key = store === cloudPersistentStore ? "HistoryTokenCloud" : "HistoryTokenLocal"
        if let data = try? NSKeyedArchiver.archivedData(withRootObject: newToken, requiringSecureCoding: true) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }


}
