
//  Persistence.swift
//  ChineseWordOfTheDay
//
//  Created by m on 6/27/23.
//

import Foundation
import CoreData
import Combine

class PersistenceController {
    static let shared = PersistenceController(actor: .swiftuiApp)
    weak var delegate: CurrentWordRefreshDelegate?
     private var _cloudPersistentStore: NSPersistentStore?
        var cloudPersistentStore: NSPersistentStore {
            return _cloudPersistentStore!
        }
        private var _localPersistentStore: NSPersistentStore?
        var localPersistentStore: NSPersistentStore {
            return _localPersistentStore!
        }
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true, actor: .swiftuiApp)
        let viewContext = result.container.viewContext
        do {
            try viewContext.save()
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
        return result
    }()
    let container: NSPersistentCloudKitContainer
    var context: NSManagedObjectContext {
        self.container.viewContext
    }
    init(inMemory: Bool = false, actor: StorageActor) {
        container = NSPersistentCloudKitContainer(name: STORE_NAME)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions.first!.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }
        let cloudURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                      .appendingPathComponent("cloud.sqlite")
        let localURL = Self.localStoreURL
        let cloudDesc = NSPersistentStoreDescription(url: cloudURL)
        cloudDesc.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.matthedm.ChineseWordOfTheDay")
        cloudDesc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        cloudDesc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        cloudDesc.cloudKitContainerOptions!.databaseScope = .private

        cloudDesc.configuration = "cloud"
        let localDesc = NSPersistentStoreDescription(url: localURL)
        localDesc.configuration = "local"
        container.persistentStoreDescriptions = [cloudDesc, localDesc]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
            if storeDescription.cloudKitContainerOptions != nil {
                // This is the CloudKit-backed store
                self._cloudPersistentStore = self.container.persistentStoreCoordinator.persistentStore(for: storeDescription.url!)
            } else {
                // This is the local store
                self._localPersistentStore = self.container.persistentStoreCoordinator.persistentStore(for: storeDescription.url!)
            }

        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.name = "viewContext"
        NotificationCenter.default.addObserver(self, selector: #selector(processRemoteChanges(_:)),
                                               name: .NSPersistentStoreRemoteChange,
                                               object: container.persistentStoreCoordinator)
    }
}

extension PersistenceController {
    private static let fm: FileManager = {
        FileManager.default
    }()
    private static let appSupport: URL = {
        /// will create the appSupportDirectory if it doesn't exist already
        try! fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }()
    private static let localStoreURL: URL = {
        appSupport.appendingPathComponent(STORE_NAME + ".sqlite")
    }()
    private static let userDefaultsKeyHasRunBefore = "hasRunBefore"
}

extension PersistenceController {
    /// Returns true if this is the first time the application has been run.
    static func isFirstRunOfApplication() -> Bool {
        return !UserDefaults.standard.bool(forKey: Self.userDefaultsKeyHasRunBefore)
    }
    /// Sets user defaults value so on the next run `isFirstRunOfApplication` will return false
    static func updateUserDefaultsToHasRunBefore(){
        UserDefaults.setValue(true, forKey: Self.userDefaultsKeyHasRunBefore)
    }
    /// Ensures that when application is first run, a preloaded database will be copied into the Sandbox.
    /// For this function to work correctly, it must be that the store was previously set to journal mode.
    /// I did this by executing the sql command 'PRAGMA journal_mode = delete;' on the store.
    static func copyDatabaseIfNeeded() {
        guard let bundlePath = Bundle.main.path(forResource: STORE_NAME, ofType: "sqlite") else {
            print("Database file not found in the app bundle.")
            return
        }
        let destinationURL = localStoreURL
        if !fm.fileExists(atPath: destinationURL.path) {
            do {
                try fm.copyItem(atPath: bundlePath, toPath: destinationURL.path)
                print("Database file copied to Application Support directory")
            } catch {
                print("Error copying database file: \(error)")
                print(Word())
                fatalError()
            }
        } else {
            print("Database file already exists in the documents directory at: ")
            print(destinationURL)
        }
    }
}

/// This code is for history stuff
extension NSPersistentCloudKitContainer {
    func newTaskContext() -> NSManagedObjectContext {
        let context = newBackgroundContext()
        context.transactionAuthor = StorageActor.swiftuiApp.rawValue
        return context
    }

}

extension PersistenceController{
    /**
     Track the last history tokens for the stores.
     The historyQueue reads the token when executing operations, and updates it after completing the processing.
     Access this user default from the history queue.
     */
    private func historyToken(with storeUUID: String) -> NSPersistentHistoryToken? {
        let key = "HistoryToken" + storeUUID
        if let data = UserDefaults.standard.data(forKey: key) {
            return  try? NSKeyedUnarchiver.unarchivedObject(ofClass: NSPersistentHistoryToken.self, from: data)
        }
        return nil
    }
    
    private func updateHistoryToken(with storeUUID: String, newToken: NSPersistentHistoryToken) {
        let key = "HistoryToken" + storeUUID
        let data = try? NSKeyedArchiver.archivedData(withRootObject: newToken, requiringSecureCoding: true)
        UserDefaults.standard.set(data, forKey: key)
    }
    //
    //    func lastUpdated() -> Date? {
    //        return UserDefaults.standard.object(forKey: "PersistentHistoryTracker.lastUpdate.\(actor.rawValue)") as? Date
    //    }
    //
    //    func persistLastUpdated(_ date: Date) {
    //        return UserDefaults.standard.set(date, forKey: "PersistentHistoryTracker.lastUpdate.\(actor.rawValue)")
    //    }
    //
    //    func leastRecentUpdate() -> Date? {
    //        return StorageActor.allCases.reduce(nil) { currentLeastRecent, actor in
    //            guard let updateDate = UserDefaults.standard.object(forKey: "PersistentHistoryTracker.lastUpdate.\(actor.rawValue)") as? Date else {
    //                return currentLeastRecent
    //            }
    //
    //            if let oldDate = currentLeastRecent {
    //                return min(oldDate, updateDate)
    //            }
    //
    //            return updateDate
    //        }
    //    }
}

// MARK: - Notification handlers that trigger history processing.
extension PersistenceController {
    @objc
    public func processRemoteChanges(_ notification: Notification) {
        guard let storeUUID = notification.userInfo?[NSStoreUUIDKey] as? String,
              self.cloudPersistentStore.identifier == storeUUID
        else {
            print("\(#function): Ignore a store remote Change notification because of no valid storeUUID.")
            
            return
        }
        let context = self.container.newTaskContext()
        context.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        let lastHistoryToken = historyToken(with: storeUUID)
        
//        let lastDate = self.lastUpdted() ?? .distantPast
        
        let request = NSPersistentHistoryChangeRequest.fetchHistory(after: lastHistoryToken)
        request.affectedStores =  [self.cloudPersistentStore]
        
        context.perform { [unowned self] in
            do {
                let result = (try? context.execute(request)) as? NSPersistentHistoryResult
                guard let transactions = result?.result as? [NSPersistentHistoryTransaction] else {
                    return
                }

                if let newToken = transactions.last?.token {
                    updateHistoryToken(with: storeUUID, newToken: newToken)
                }
                
                if let del = self.delegate {
                    DispatchQueue.main.async{
                        del.refresh()
                    }
                }
            
                
//                for transaction in history {
//                    let notification = transaction.objectIDNotification()
//                    context.mergeChanges(fromContextDidSave: notification)
//                    self.persistLastUpdated(transaction.timestamp)
//                }

//                if let lastTimestamp = leastRecentUpdate() {
//                    let deleteRequest = NSPersistentHistoryChangeRequest.deleteHistory(before: lastTimestamp)
//                    try context.execute(deleteRequest)
//                }
            } catch {
                print(error)
            }
        }
    }
}

public enum StorageActor: String, CaseIterable {
    case swiftuiApp, uikitApp
}

