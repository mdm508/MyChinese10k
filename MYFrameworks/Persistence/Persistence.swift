
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
        let localDesc = NSPersistentStoreDescription(url: Self.appGroupURL)
        localDesc.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        localDesc.setOption(true as NSNumber, forKey: NSPersistentStoreRemoteChangeNotificationPostOptionKey)
        localDesc.configuration = "local"
        container.persistentStoreDescriptions.append(localDesc)
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
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
        guard let bundlePath = Bundle.main.path(forResource: Constants.STORE_NAME, ofType: "sqlite") else {
            print("Database file not found in the app bundle.")
            return
        }
        let destinationURL = appGroupURL
        if !fm.fileExists(atPath: destinationURL.path) {
            do {
                try fm.copyItem(atPath: bundlePath, toPath: destinationURL.path)
                print("Database file copied to AppGroup Container")
                print(destinationURL)
            } catch {
                print("Error copying database file: \(error)")
                fatalError()
            }
        } else {
            print("Database file already exists in the documents directory at: ")
            print(destinationURL)
        }
    }
    // Convenience function to delete SQLite file
    public static func deleteDatabase() {
        let fileManager = fm
        let storeURL = appGroupURL
        
        do {
            if fileManager.fileExists(atPath: storeURL.path) {
                try fileManager.removeItem(at: storeURL)
                print("Database deleted successfully.")
            } else {
                print("Database not found at path: \(storeURL.path).")
            }
        } catch {
            print("Error deleting database: \(error)")
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


