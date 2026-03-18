////
////  Persistence+History.swift
////  ChineseWordOfTheDay
////
////  Created by m on 12/30/23.
////
//
import CoreData
import Foundation
import CoreDataModels

/*
 A small helper object whose only job is to consume persistent history
 for the CloudKit-backed Core Data store.

 Why this exists:
 - loadPersistentStores only means the stores are open and usable
 - CloudKit imports can arrive later
 - when they do, Core Data posts .NSPersistentStoreRemoteChange
 - this class responds by reading persistent history after the last token
 - then it merges those changes into viewContext so fetched UI can refresh

 This gives you a clean pipeline:

 remote store change
 -> read new history
 -> merge changes into viewContext
 -> fetched UI sees updated data
*/
final class PersistentHistoryTracker {

    /*
     The Core Data container that owns the stores.

     We need this so we can:
     - create a background context for reading history
     - access the persistent store coordinator
     - merge changes into the main viewContext
    */
    private let container: NSPersistentCloudKitContainer

    /*
     A serial queue used to process history in order.

     Why serial matters:
     - persistent history is incremental
     - the token must move forward in the correct order
     - overlapping reads could process the same history twice
       or save the wrong "latest" token

     So all history work is funneled through this one queue.
    */
    private let historyQueue = OperationQueue()

    /*
     The specific CloudKit-backed store whose history we want to read.

     Your container has both a local store and a cloud store.
     We only want the history associated with the cloud-backed one.
    */
    private let cloudStore: NSPersistentStore

    /*
     The App Group identifier used to access shared UserDefaults.

     We store the persistent history token there so the token survives app relaunches
     and can be shared across processes if needed.
    */
    private let appGroupIdentifier: String

    /*
     The unique key used to save and load the history token.

     We include the persistent store identifier so the token is tied to
     this exact store and not some other store.
    */
    private var historyTokenKey: String {
        "PersistentHistoryToken-\(cloudStore.identifier ?? "unknownStore")"
    }

    /*
     Create a tracker for one CloudKit container.

     What setup happens here:
     - save the container reference
     - save the App Group identifier
     - configure the serial queue
     - locate the persistent store whose configuration name is "cloud"

     Why this can fail:
     - if the stores have not been loaded yet
     - or if there is no store configured as "cloud"

     So this initializer is failable.
    */
    init?(
        container: NSPersistentCloudKitContainer,
        appGroupIdentifier: String
    ) {
        self.container = container
        self.appGroupIdentifier = appGroupIdentifier
        self.historyQueue.maxConcurrentOperationCount = 1
        self.historyQueue.name = "PersistentHistoryTrackerQueue"

        guard
            let store = container.persistentStoreCoordinator.persistentStores.first(where: {
                $0.configurationName == "cloud"
            })
        else {
            print("PersistentHistoryTracker init failed: could not find cloud store.")
            return nil
        }

        self.cloudStore = store
    }

    /*
     Begin listening for persistent-store remote change notifications.

     This notification is the signal that the store changed.
     It does not itself contain all the transaction details we need.

     Instead, when this fires, we treat it as:
     "something new may have landed in the store; go read persistent history."
    */
    func start() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleRemoteStoreChange(_:)),
            name: .NSPersistentStoreRemoteChange,
            object: container.persistentStoreCoordinator
        )
    }

    /*
     Stop listening for store-change notifications.

     This is useful if the tracker is being torn down and you want to avoid
     leaving a notification observer around.
    */
    func stop() {
        NotificationCenter.default.removeObserver(self)
    }

    /*
     Respond to a remote store change notification.

     Important:
     - this function should stay very light
     - do not do actual history fetch work directly here
     - instead, schedule the work onto the serial history queue

     Think of this as the "tap on the shoulder" handler.
    */
    @objc
    private func handleRemoteStoreChange(_ notification: Notification) {
        processHistoryAsynchronously()
    }

    /*
     Schedule persistent-history processing on the serial queue.

     Why not do the work immediately:
     - history reads touch disk
     - history processing may take some time
     - we do not want notification delivery or the main thread blocked

     Why use a background context:
     - persistent history should be fetched off the main thread
     - then the resulting changes can be merged into viewContext afterward
    */
    private func processHistoryAsynchronously() {
        historyQueue.addOperation { [weak self] in
            guard let self else { return }

            let context = self.container.newBackgroundContext()
            context.name = "PersistentHistoryTrackerContext"
            context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy

            context.performAndWait {
                self.performHistoryProcessing(using: context)
            }
        }
    }

    /*
     Fetch and apply all persistent history newer than the last saved token.

     High-level algorithm:
     1. Load the last token we processed.
     2. Ask Core Data for all transactions after that token.
     3. Restrict the request to the cloud store.
     4. Convert the returned transactions into one merged userInfo dictionary.
     5. Merge that dictionary into viewContext.
     6. Save the newest token so next time we continue from there.

     Why this matters:
     - CloudKit import may finish after app launch
     - this is how later-arriving imported changes get surfaced to your UI
    */
    private func performHistoryProcessing(using context: NSManagedObjectContext) {
        let lastToken: NSPersistentHistoryToken? = loadHistoryToken()

        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastToken)
        request.resultType = .transactionsOnly
        request.affectedStores = [cloudStore]

        do {
            guard
                let result = try context.execute(request) as? NSPersistentHistoryResult,
                let transactions = result.result as? [NSPersistentHistoryTransaction],
                !transactions.isEmpty
            else {
                return
            }
            try deduplicateWordIndex(using: context)
            let userInfo = mergeUserInfo(from: transactions)

            /*
             Merge the changes into viewContext on viewContext's own queue.

             Why:
             - viewContext is typically main-queue based
             - merging on the wrong queue can cause threading bugs
             - once merged, fetched results / observed objects can refresh
            */
            container.viewContext.performAndWait {
                NSManagedObjectContext.mergeChanges(
                    fromRemoteContextSave: userInfo,
                    into: [container.viewContext]
                )
            }

            /*
             Advance the token only after successful processing.

             This ensures that next time we fetch only newer transactions.
            */
            if let newToken = transactions.last?.token {
                saveHistoryToken(newToken)
            }
            DispatchQueue.main.async {
                // Let anyone who is interete (cough cough... WordService)
                //know that changes have been merged in and its time to fetch.
                NotificationCenter.default.post(name: .cdcksStoreDidChange, object: nil)
            }

            print("Processed \(transactions.count) persistent history transaction(s).")
        } catch {
            print("Persistent history processing failed: \(error)")
        }
    }

    /*
     Combine many transactions into one mergeable userInfo dictionary.

     Each NSPersistentHistoryTransaction can produce a notification-shaped
     dictionary containing inserted, updated, and deleted object IDs.

     We union those IDs across all transactions so we can do one merge into
     viewContext instead of many little merges.
    */
    private func mergeUserInfo(
        from transactions: [NSPersistentHistoryTransaction]
    ) -> [AnyHashable: Any] {
        var inserted = Set<NSManagedObjectID>()
        var updated = Set<NSManagedObjectID>()
        var deleted = Set<NSManagedObjectID>()

        for transaction in transactions {
            guard let userInfo = transaction.objectIDNotification().userInfo else {
                continue
            }

            if let ids = userInfo[NSInsertedObjectsKey] as? Set<NSManagedObjectID> {
                inserted.formUnion(ids)
            }

            if let ids = userInfo[NSUpdatedObjectsKey] as? Set<NSManagedObjectID> {
                updated.formUnion(ids)
            }

            if let ids = userInfo[NSDeletedObjectsKey] as? Set<NSManagedObjectID> {
                deleted.formUnion(ids)
            }
        }

        var merged: [AnyHashable: Any] = [:]
        if !inserted.isEmpty { merged[NSInsertedObjectsKey] = inserted }
        if !updated.isEmpty { merged[NSUpdatedObjectsKey] = updated }
        if !deleted.isEmpty { merged[NSDeletedObjectsKey] = deleted }
        return merged
    }

    /*
     Load the last processed persistent-history token from shared defaults.

     If no token exists yet, return nil.
     That means:
     "we have never processed history before, so fetch from the beginning."

     The token is archived data because NSPersistentHistoryToken is not a simple
     primitive type that UserDefaults can store directly.
    */
    private func loadHistoryToken() -> NSPersistentHistoryToken? {
        guard
            let defaults = UserDefaults(suiteName: appGroupIdentifier),
            let data = defaults.data(forKey: historyTokenKey)
        else {
            return nil
        }

        return try? NSKeyedUnarchiver.unarchivedObject(
            ofClass: NSPersistentHistoryToken.self,
            from: data
        )
    }

    /*
     Save the newest processed token into shared defaults.

     Why save it:
     - so the next history read can continue incrementally
     - so we do not repeatedly reprocess old transactions
     - so the app can resume correctly after relaunch

     If saving fails, history consumption will still work for the current run,
     but future runs may reread older history.
    */
    private func saveHistoryToken(_ token: NSPersistentHistoryToken) {
        guard let defaults = UserDefaults(suiteName: appGroupIdentifier) else {
            return
        }

        do {
            let data = try NSKeyedArchiver.archivedData(
                withRootObject: token,
                requiringSecureCoding: true
            )
            defaults.set(data, forKey: historyTokenKey)
        } catch {
            print("Failed to save history token: \(error)")
        }
    }
    /*
     Deduplicate the singleton WordIndex entity.

     Strategy:
     - fetch all WordIndex rows from the cloud-backed world
     - if there is 0 or 1 row, do nothing (nothing to de-duplicate)
     - choose one deterministic winner (highest wins)
     - delete the rest
     - save the context

     Why this works:
     - CloudKit + Core Data does not enforce uniqueness constraints here
     - so we repair the data after import instead of relying on the store
    */
    private func deduplicateWordIndex(using context: NSManagedObjectContext) throws {
        print("running de-duplicateWordIndex")
        let request: NSFetchRequest<WordIndex> = WordIndex.fetchRequest()
        let all = try context.fetch(request)
        guard all.count > 1 else { return }
        let winner = all.max { maxSoFar, rhs in
            return maxSoFar.current <= rhs.current
        }
        guard let winner else { return }
        for index in all where index.objectID != winner.objectID {
            context.delete(index)
        }
        if context.hasChanges {
            try context.save()
        }
    }
}

//extension PersistenceController{
//    private func processPersistentHistory() {
//        let taskContext = container.newBackgroundContext()
//        taskContext.perform {
//            let request: NSPersistentHistoryChangeRequest
//
//            if let token = self.loadHistoryToken() {
//                request = NSPersistentHistoryChangeRequest.fetchHistory(after: token)
//            } else {
//                request = NSPersistentHistoryChangeRequest.fetchHistory(after: nil)
//            }
//
//            request.resultType = .transactionsOnly
//
//            do {
//                let result = try taskContext.execute(request) as? NSPersistentHistoryResult
//                let transactions = result?.result as? [NSPersistentHistoryTransaction] ?? []
//
//                guard !transactions.isEmpty else { return }
//
//                let newToken = transactions.last?.token
//
//                let changes = transactions.compactMap(\.objectIDNotification).reduce(into: [AnyHashable: Any]()) { partial, note in
//                    for (k, v) in note.userInfo ?? [:] {
//                        let existing = partial[k] as? Set<NSManagedObjectID> ?? []
//                        let incoming = v as? Set<NSManagedObjectID> ?? []
//                        partial[k] = existing.union(incoming)
//                    }
//                }
//
//                NSManagedObjectContext.mergeChanges(
//                    fromRemoteContextSave: changes,
//                    into: [self.container.viewContext]
//                )
//
//                if let newToken {
//                    self.saveHistoryToken(newToken)
//                }
//            } catch {
//                print("Persistent history error:", error)
//            }
//        }
//    }
//    private func saveHistoryToken(_ token: NSPersistentHistoryToken) {
//        do {
//            let data = try NSKeyedArchiver.archivedData(withRootObject: token, requiringSecureCoding: true)
//            UserDefaults(suiteName: "group.com.your.app")?.set(data, forKey: "historyToken")
//        } catch {
//            print("save token error:", error)
//        }
//    }
//
//    private func loadHistoryToken() -> NSPersistentHistoryToken? {
//        guard
//            let data = UserDefaults(suiteName: "group.com.your.app")?.data(forKey: "historyToken"),
//            let token = try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
//        else {
//            return nil
//        }
//        return token
//    }
//}






//// MARK: - Notification handlers that trigger history processing.
//extension PersistenceController {
//    /**
//     Handle the container's event changed notifications (NSPersistentCloudKitContainer.eventChangedNotification).
//     */
//    @objc
//    func containerEventChanged(_ notification: Notification) {
//         guard let value = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey],
//              let event = value as? NSPersistentCloudKitContainer.Event else {
//            print("\(#function): Failed to retrieve the container event from notification.userInfo.")
//            return
//        }
//        if event.error != nil {
//            print("\(#function): Received a persistent CloudKit container event changed notification.\n\(event)")
//        }
//    }
//}

//// MARK: - Process persistent historty asynchronously
//@MainActor
//extension PersistenceController {
//    /**
//     Process persistent history, posting any relevant transactions to the current view.
//     This method processes the new history since the last history token, and is simply a fetch if there is no new history.
//     */
//    func processHistoryAsynchronously() {
//        historyQueue.addOperation {
//            let taskContext = self.container.newTaskContext()
//            taskContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//            taskContext.performAndWait {
//                self.performHistoryProcessing(performingContext: taskContext)
//            }
//        }
//    }
//    /**
//     Fetch history received from outside the app since the last timestamp
//    */
//    private func performHistoryProcessing(performingContext: NSManagedObjectContext) {
//        // Prepare to make history fetch request on iCloud container
//        let lastHistoryToken = historyToken()
//        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryToken)
//        let historyFetchRequest = NSPersistentHistoryTransaction.fetchRequest!
//        historyFetchRequest.predicate = NSPredicate(format: "author != %@", StorageActor.swiftuiApp.rawValue)
//        request.fetchRequest = historyFetchRequest
//        request.affectedStores =  [self.cloudPersistentStore]
//        let context = self.container.newTaskContext()
//        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
//        // Do the fetch
//        let result = (try? performingContext.execute(request)) as? NSPersistentHistoryResult
//        guard let transactions = result?.result as? [NSPersistentHistoryTransaction] else {
//            return
//        }
//        print("\(#function): Processing transactions: \(transactions.count).")
//
//        // Post transactions so observers can update UI if necessary, even when transactions are empty.
//        //TODO! Filter and then post or dont post at all
//        //        let userInfo: [String: Any] = [UserInfoKey.storeUUID: self.cloudPersistentStore.identifier!,
////                                       UserInfoKey.transactions: transactions]
////        NotificationCenter.default.post(name: .cdcksStoreDidChange, object: self, userInfo: userInfo)
//        // Update the history token using the last transaction. The last transaction has the latest token.
//        if let newToken = transactions.last?.token {
//            updateHistoryToken(newToken: newToken)
//        }
//        // Check if we need to even bother with de-duplications
//        guard !transactions.isEmpty else {
//            return
//        }
//        // De-duplicate words
//        var newWordStatusObjectIDs = [NSManagedObjectID]()
//        let wordStatusEntityName = WordStatus.entity().name
//        // Gather all WordStatus id's for insertions
//        for transaction in transactions where transaction.changes != nil {
//            for change in transaction.changes! {
//                if change.changedObjectID.entity.name == wordStatusEntityName && change.changeType == .insert {
//                    newWordStatusObjectIDs.append(change.changedObjectID)
//                }
//            }
//        }
//        if !newWordStatusObjectIDs.isEmpty {
//            deduplicateWordStatusesAndWait(statusObjectIDs: newWordStatusObjectIDs)
//        }
//    }
//}
//extension PersistenceController{
//    /**
//     Track the last history tokens for the stores.
//     The historyQueue reads the token when executing operations, and updates it after completing the processing.
//     Access this user default from the history queue.
//     */
//    func historyToken() -> NSPersistentHistoryToken? {
//        let key = "HistoryToken" + self.cloudPersistentStore.identifier
//        if let data = UserDefaults.standard.data(forKey: key) {
//            return  try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
//        }
//        return nil
//    }
//    func updateHistoryToken(newToken: NSPersistentHistoryToken) {
//        let key = "HistoryToken" + self.cloudPersistentStore.identifier
//        let data = try? NSKeyedArchiver.archivedData(withRootObject: newToken, requiringSecureCoding: true)
//        UserDefaults.standard.set(data, forKey: key)
//    }
//}
