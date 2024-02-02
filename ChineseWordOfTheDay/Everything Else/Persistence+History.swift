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
    func processHistoryAsynchronously() {
        historyQueue.addOperation {
            let taskContext = self.container.newTaskContext()
            taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            taskContext.performAndWait {
                self.performHistoryProcessing(performingContext: taskContext)
            }
        }
    }
    /**
     Fetch history received from outside the app since the last timestamp
    */
    private func performHistoryProcessing(performingContext: NSManagedObjectContext) {
        // Prepare to make history fetch request on iCloud container
        let lastHistoryToken = historyToken()
        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryToken)
        let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest!
        historyFetchRequest.predicate = NSPredicate(format: "author != %@", StorageActor.swiftuiApp.rawValue)
        request.fetchRequest = historyFetchRequest
        request.affectedStores =  [self.cloudPersistentStore]
        let context = self.container.newTaskContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        // Do the fetch
        let result = (try? performingContext.execute(request)) as? NSPersistentHistoryResult
        guard let transactions = result?.result as? [NSPersistentHistoryTransaction] else {
            return
        }
        print("\(#function): Processing transactions: \(transactions.count).")

        // Post transactions so observers can update UI if necessary, even when transactions are empty.
        let userInfo: [String: Any] = [UserInfoKey.storeUUID: self.cloudPersistentStore.identifier!,
                                       UserInfoKey.transactions: transactions]
        NotificationCenter.default.post(name: .cdcksStoreDidChange, object: self, userInfo: userInfo)
        // Update the history token using the last transaction. The last transaction has the latest token.
        if let newToken = transactions.last?.token {
            updateHistoryToken(newToken: newToken)
        }
        // Check if we need to even bother with de-duplications
        guard !transactions.isEmpty else {
            return
        }
        // De-duplicate words
        var newWordStatusObjectIDs = [NSManagedObjectID]()
        let wordStatusEntityName = WordStatus.entity().name
        // Gather all WordStatus id's for insertions
        for transaction in transactions where transaction.changes != nil {
            for change in transaction.changes! {
                if change.changedObjectID.entity.name == wordStatusEntityName && change.changeType == .insert {
                    newWordStatusObjectIDs.append(change.changedObjectID)
                }
            }
        }
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
    func historyToken() -> NSPersistentHistoryToken? {
        let key = "HistoryToken" + self.cloudPersistentStore.identifier
        if let data = UserDefaults.standard.data(forKey: key) {
            return  try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
        }
        return nil
    }
    func updateHistoryToken(newToken: NSPersistentHistoryToken) {
        let key = "HistoryToken" + self.cloudPersistentStore.identifier
        let data = try? NSKeyedArchiver.archivedData(withRootObject: newToken, requiringSecureCoding: true)
        UserDefaults.standard.set(data, forKey: key)
    }
}
