
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
}

extension NotificationCenter {
    public var storeDidChangePublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .cdcksStoreDidChange).receive(on: DispatchQueue.main)
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

@MainActor
public class PersistenceController {
    public static var shared = PersistenceController(actor: .swiftuiApp)
//    public weak var delegate: CurrentWordRefreshDelegate?
    static var widget: PersistenceController {
        let con = PersistenceController(actor: .widget)
        return con
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
    public var context: NSManagedObjectContext {
        self.container.viewContext
    }
    public init(inMemory: Bool = false, actor: StorageActor) {
        setupCloudSub()
        ValueTransformer.setValueTransformer(
            StringArrayTransformer(),
            forName: NSValueTransformerName("StringArrayTransformer")
        )
        let model = ModelLoader.loadModel()
        container = NSPersistentCloudKitContainer(name: ModelLoader.name, managedObjectModel: model)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions.first!.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }
        container.persistentStoreDescriptions = []
        if actor == .swiftuiApp{
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

        }
        if actor == .widget {
            print("hi im widget")
        }
//         MARK: - Local Configuration
        // --- Local store (App Group) ---
        let localURL = Self.appGroupURL

        // 🔑 Manual compatibility check (wipe + reseed if outdated or corrupt)
        if !PersistenceController.storeIsCompatible(with: model, at: localURL) {
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

        container.persistentStoreDescriptions.append(localDesc)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                print("Loaded store:", localDesc.url?.path ?? "nil", " config:", localDesc.configuration ?? "nil")
                assert(localDesc.url == PersistenceController.appGroupURL, "Not the App Group store!")
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.name = "viewContext"
        //        NotificationCenter.default.addObserver(self, selector: #selector(storeRemoteChange(_:)),
        //                                               name: .NSPersistentStoreRemoteChange,
        //                                               object: container.persistentStoreCoordinator)
    }
}


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
        
        
        
        // Convenience function to delete SQLite file
    public static func deleteDatabase() {
        let fm = FileManager.default
        let storeURL = appGroupURL
        
        do {
            // Remove main store
            if fm.fileExists(atPath: storeURL.path) {
                try fm.removeItem(at: storeURL)
                print("✅ Deleted:", storeURL.lastPathComponent)
            }
            // Remove WAL + SHM sidecars
            for ext in ["-wal", "-shm"] {
                let sidecar = storeURL.path + ext
                if fm.fileExists(atPath: sidecar) {
                    try fm.removeItem(atPath: sidecar)
                    print("✅ Deleted sidecar:", (sidecar as NSString).lastPathComponent)
                }
            }
        } catch {
            print("❌ Error deleting database: \(error)")
        }
    }
}


// MARK: - Notification handlers that trigger history processing.
extension NSPersistentCloudKitContainer {
    func newTaskContext() -> NSManagedObjectContext {
        let context = newBackgroundContext()
        context.transactionAuthor = StorageActor.swiftuiApp.rawValue
        return context
    }
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


