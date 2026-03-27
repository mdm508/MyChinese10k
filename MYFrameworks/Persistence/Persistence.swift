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

public class PersistenceController {
    public static var shared = PersistenceController(actor: .swiftuiApp)
    private var historyTracker: PersistentHistoryTracker?
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
    /**
     A serial queue ensures history processing happens in order.

     Why this matters:
     - persistent history is processed incrementally
     - the history token must move forward in a reliable sequence
     - if two history-processing jobs overlap, they can race and save the wrong token

     So all reads/writes of the history token should happen on this queue.
    */
    /// Publishes a notification when ready to go. This is needed if initial sync is slow on first time install.
    @Published public private(set) var isReady = false
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
        print("Persistent store is ready to go.")
        self.isReady = true
    }
    deinit {
        historyTracker?.stop()
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
