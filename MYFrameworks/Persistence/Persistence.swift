//  Persistence.swift
//  ChineseWordOfTheDay
//
//  Created by m on 6/27/23.
//

import Foundation
import CoreData
import Combine
import UIKit
import CloudKit
import CoreDataModels

public enum StorageActor: String, CaseIterable {
    case swiftuiApp, widget
}

/**
 We might post notifications from a background queueue.
 */
extension Notification.Name {
    public static let cdcksStoreDidChange = Notification.Name("cdcksStoreDidChange")
    public static let nowWeReady = Notification.Name("nowWeReady")

}

extension NotificationCenter {
    public var storeDidChangePublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .cdcksStoreDidChange).receive(on: DispatchQueue.main)
    }
    public var nowWeReadyPublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        publisher(for: .nowWeReady).receive(on: DispatchQueue.main)
    }
}

struct UserInfoKey {
    static let storeUUID = "storeUUID"
    static let transactions = "transactions"
}


extension PersistenceController {
    /// Returns true if the on-disk SQLite at `url` is compatible with `model`.
    /// If the file doesn't exist or metadata can't be read, returns false (so you reseed).
    public static func storeIsCompatible(with model: NSManagedObjectModel,
                                         at url: URL,
                                         configuration: String? = "local") -> Bool {
        guard FileManager.default.fileExists(atPath: url.path) else { return false }
        do {
            let metadata = try NSPersistentStoreCoordinator.metadataForPersistentStore(
                ofType: NSSQLiteStoreType,
                at: url
            )
            // Prefer the named config, fall back to default (nil) if needed
            if let configuration = configuration,
               model.isConfiguration(withName: configuration, compatibleWithStoreMetadata: metadata) {
                return true
            }
            return model.isConfiguration(withName: nil, compatibleWithStoreMetadata: metadata)
        } catch {
            return false
        }
    }
}

public class PersistenceController {
    public static var shared = PersistenceController(actor: .swiftuiApp)
    private var historyTracker: PersistentHistoryTracker?
//    public weak var delegate: CurrentWordRefreshDelegate?
    static var widget: PersistenceController {
        let con = PersistenceController(actor: .widget)
        return con
    }
    public static var preview: PersistenceController = {
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
    public var context: NSManagedObjectContext {
        self.container.viewContext
    }
    /*
     A serial queue ensures history processing happens in order.

     Why this matters:
     - persistent history is processed incrementally
     - the history token must move forward in a reliable sequence
     - if two history-processing jobs overlap, they can race and save the wrong token

     So all reads/writes of the history token should happen on this queue.
    */
    private let historyQueue = OperationQueue()
    public init(inMemory: Bool = false, actor: StorageActor) {
        // WARNING: - this will delete everything on the cloud and locally then exit
        ValueTransformer.setValueTransformer(
            StringArrayTransformer(),
            forName: NSValueTransformerName("StringArrayTransformer")
        )
        let model = ModelLoader.loadModel()
        container = NSPersistentCloudKitContainer(name: ModelLoader.name, managedObjectModel: model)
        if inMemory {
            // Use a single in-memory store for tests/previews (local configuration only)
            let localDesc = NSPersistentStoreDescription()
            localDesc.type = NSInMemoryStoreType
            localDesc.configuration = "local"
            localDesc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)

            container.persistentStoreDescriptions = [localDesc]
            container.loadPersistentStores { (storeDescription, error) in
                if let error = error as NSError? {
                    print("❌ Failed to load in-memory store:", storeDescription.url?.path ?? "nil", "config:", storeDescription.configuration ?? "nil")
                    fatalError("Unresolved error \(error), \(error.userInfo)")
                } else {
                    print("✅ Loaded in-memory store:", storeDescription.url?.path ?? "nil", "config:", storeDescription.configuration ?? "nil")
                }
            }
            container.viewContext.automaticallyMergesChangesFromParent = true
            container.viewContext.name = "viewContext"
            container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            return
        }
        container.persistentStoreDescriptions = []
        // MARK: - Cloud Configuration
        let cloudURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
                      .appendingPathComponent("cloud.sqlite")
        let cloudDesc = NSPersistentStoreDescription(url: cloudURL)
        cloudDesc.cloudKitContainerOptions = NSPersistentCloudKitContainerOptions(containerIdentifier: "iCloud.com.matthedm.ChineseWordOfTheDay")
        cloudDesc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        cloudDesc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        cloudDesc.cloudKitContainerOptions!.databaseScope = .private
        cloudDesc.configuration = "cloud"
        container.persistentStoreDescriptions = [cloudDesc]
//         MARK: - Local Configuration
        // --- Local store (App Group) ---
        let localURL = Self.appGroupURL

        // 🔑 Manual compatibility check (wipe + reseed if outdated or corrupt)
        if !PersistenceController.storeIsCompatible(with: model, at: localURL) {
            print("INCOMPATIBLE STORE")
            let fm = FileManager.default
            try? fm.removeItem(at: localURL)
            try? fm.removeItem(at: localURL.appendingPathExtension("wal"))
            try? fm.removeItem(at: localURL.appendingPathExtension("shm"))
            PersistenceController.copyDatabaseIfNeeded()
        }

        // Describe and append the local store
        let localDesc = NSPersistentStoreDescription(url: localURL)
        localDesc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        localDesc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        localDesc.configuration = "local"
        // (Recommended)
        localDesc.shouldMigrateStoreAutomatically = true
        localDesc.shouldInferMappingModelAutomatically = true

        if !container.persistentStoreDescriptions.contains(where: { $0.url == localURL }) {
            container.persistentStoreDescriptions.append(localDesc)
        }
        container.loadPersistentStores { (storeDescription, error) in
            if let error = error as NSError? {
                print("Failed to load store at:", storeDescription.url?.path ?? "nil", "config:", storeDescription.configuration ?? "nil")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            } else {
                print("Loaded store:", storeDescription.url?.path ?? "nil", "config:", storeDescription.configuration ?? "nil")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.name = "viewContext"
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        //debug
        historyTracker = PersistentHistoryTracker(
            container: container,
            appGroupIdentifier: Constants.appGroupId
        )
        historyTracker?.start()

        print("done")
        print("done")
    }
    deinit {
        historyTracker?.stop()
    }
    
}



//extension PersistenceController {
////    @objc
////    func containerEventChanged(_ notification: Notification) {
////        return
////    }
//    
//    @objc
//    nonisolated func containerEventChanged(_ notification: Notification) {
//        guard
//            let value = notification.userInfo?[NSPersistentCloudKitContainer.eventNotificationUserInfoKey],
//            let event = value as? NSPersistentCloudKitContainer.Event
//        else { return }
//
//        print("CloudKit event:", event.type.rawValue)
//
//        if let error = event.error {
//            print("CloudKit error:", error)
//            return
//        }
//
//        guard event.type == .import else { return }
//
//        print("Cloud data imported")
//
//        let context = container.newBackgroundContext()
//
//        context.perform {
//            self.deduplicateLocally(context: self.container.newBackgroundContext())
//
//            DispatchQueue.main.async {
//                NotificationCenter.default.post(name: .cdcksStoreDidChange, object: self)
//            }
//        }
//    }
//}


// MARK: - Conveinent URLS
extension PersistenceController {
    public static var appGroupURL: URL {
        let groupContainer = fm.containerURL(forSecurityApplicationGroupIdentifier: Constants.appGroupId)!
        let url = groupContainer.appendingPathComponent(Constants.STORE_NAME + ".sqlite")
        return url
    }
    private static let fm: FileManager = {
        FileManager.default
    }()
}



/**
 Handle .NSPersistentStoreRemoteChange notifications.
 Process persistent history to merge relevant changes to the context, and deduplicate the tags if necessary.
 */
//extension PersistenceController {
//    @objc
//    func storeRemoteChange(_ notification: Notification) {
//        guard let storeUUID = notification.userInfo?[NSStoreUUIDKey] as? String,
//              self.cloudPersistentStore.identifier == storeUUID
//        else {
//            print("\(#function): Ignore a store remote Change notification because of no valid storeUUID.")
//            return
//        }
////        processHistoryAsynchronously()
//    }
//}


extension PersistenceController {
    /// Deduplicate entities that cannot use Core Data uniqueness constraints when mirroring with CloudKit.
    /// - Note: This runs on the viewContext and coalesces duplicates for WordIndex and WordStatus.
    nonisolated func deduplicateLocally(context: NSManagedObjectContext) {
        context.perform {
            // Deduplicate WordIndex: keep the one with the highest `current` value
            do {
                let indexFetch: NSFetchRequest<WordIndex> = WordIndex.fetchRequest()
                let indices = try context.fetch(indexFetch)
                if indices.count > 1 {
                    if let keep = indices.max(by: { $0.current < $1.current }) {
                        indices.filter { $0 != keep }.forEach { context.delete($0) }
                    }
                }
            } catch {
                print("❌ Dedup WordIndex failed: \(error)")
            }

            // Deduplicate WordStatus by `traditional`: keep the one with the latest `lastModified` (fallback to highest status)
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
}

// MARK: - Setup PersistenceController on first run of the application
extension PersistenceController {
    /// Ensures that when application is first run, a preloaded database will be copied into the Sandbox.
    /// For this function to work correctly, it must be that the store was previously set to journal mode.
    /// I did this by executing the sql command 'PRAGMA journal_mode = delete;' on the store.
    public static func copyDatabaseIfNeeded() {
            // Framework bundle
            let bundle = Bundle(for: PersistenceController.self)

            // Look for the seed database in the framework bundle
            guard let path = bundle.path(forResource: Constants.STORE_NAME, ofType: "sqlite") else {
                fatalError("Seed database \(Constants.STORE_NAME).sqlite not found in framework bundle")
            }

            let srcURL = URL(fileURLWithPath: path)
            let dstURL = appGroupURL

            // Make sure App Group folder exists
            do {
                try fm.createDirectory(at: dstURL.deletingLastPathComponent(),
                                       withIntermediateDirectories: true,
                                       attributes: nil)
            } catch {
                fatalError("Failed to create App Group directory: \(error)")
            }

            // Copy if missing
            if !fm.fileExists(atPath: dstURL.path) {
                do {
                    try fm.copyItem(at: srcURL, to: dstURL)
                    print("Database copied to App Group: \(dstURL)")
                } catch {
                    fatalError("Error copying database: \(error)")
                }
            } else {
                print("Database already exists at: \(dstURL)")
            }
        }
    
}
