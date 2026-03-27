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

/**
 A small helper object whose  job is to consume persistent history
 for the CloudKit-backed Core Data store and preform dedeplication

 Why this exists:
 - loadPersistentStores only means the stores are open and usable
 - CloudKit imports can arrive later
 - when they do, Core Data posts .NSPersistentStoreRemoteChange
 - this class responds by reading persistent history after the last token
 - then it merges those changes into viewContext so fetched UI can refresh

 remote store change
 -> read new history
 -> merge changes into viewContext
 -> fetched UI sees updated data
*/
final class PersistentHistoryTracker {
    /**
     The Core Data container that owns the stores.

     We need this so we can:
     - create a background context for reading history
     - access the persistent store coordinator
     - merge changes into the main viewContext
    */
    private let container: NSPersistentCloudKitContainer

    /**
     A serial queue used to process history in order.

     Why serial matters:
     - persistent history is incremental
     - the token must move forward in the correct order
     - overlapping reads could process the same history twice
       or save the wrong "latest" token

     So all history work is funneled through this one queue.
    */
    private let historyQueue = OperationQueue()

    /**
     The specific CloudKit-backed store whose history we want to read.

     Your container has both a local store and a cloud store.
     We only want the history associated with the cloud-backed one.
    */
    private let cloudStore: NSPersistentStore

    /**
     The App Group identifier used to access shared UserDefaults.

     We store the persistent history token there so the token survives app relaunches
     and can be shared across processes if needed.
    */
    private let appGroupIdentifier: String

    /**
     The unique key used to save and load the history token.

     We include the persistent store identifier so the token is tied to
     this exact store and not some other store.
    */
    private var historyTokenKey: String {
        "PersistentHistoryToken-\(cloudStore.identifier ?? "unknownStore")"
    }

    /**
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

    /**
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

    /**
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

    /**
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

    /**
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
            try deduplicateWordStatus(using: context)
            let userInfo = mergeUserInfo(from: transactions)

            /**
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

            /**
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

    /**
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

    /**
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
    /**
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
    /**
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
    /// Deduplicate WordStatus by `traditional`: keep the one with the latest `lastModified` (fallback to highest status)
    private func deduplicateWordStatus(using context: NSManagedObjectContext) throws {
        print("running de-deplicateWordStatus")
        do {
            let statusFetch: NSFetchRequest<WordStatus> = WordStatus.fetchRequest()
            let all = try context.fetch(statusFetch)
            let grouped = Dictionary(grouping: all, by: { $0.traditional })
            for (_, group) in grouped where group.count > 1 {
                let keep = group.max { lhs, rhs in
                    let lDate = lhs.lastModified ?? .distantPast
                    let rDate = rhs.lastModified ?? .distantPast
                    if lDate == rDate { return lhs.status < rhs.status }
                    return lDate < rDate
                }
                if let keep = keep {
                    group.filter { $0 != keep }.forEach { context.delete($0) }
                }
            }
        } catch {
            print("❌ Dedup WordStatus failed: \(error)")
        }
        if context.hasChanges {
            do { try context.save() } catch { print("❌ Error saving after dedup: \(error)") }
        }
    }
}
