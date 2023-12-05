
//  Persistence.swift
//  ChineseWordOfTheDay
//
//  Created by m on 6/27/23.
//

import Foundation
import CoreData
import WordFramework
import Combine

struct PersistenceController {
    static let shared = PersistenceController()
    static var preview: PersistenceController = {
        let result = PersistenceController(inMemory: true)
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
    init(inMemory: Bool = false) {
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
        cloudDesc.configuration = "cloud"
        let localDesc = NSPersistentStoreDescription(url: localURL)
        localDesc.configuration = "local"
        container.persistentStoreDescriptions = [cloudDesc, localDesc]
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

extension PersistenceController {
    static let fm: FileManager = {
        FileManager.default
    }()
    static let appSupport: URL = {
        /// will create the appSupportDirectory if it doesn't exist already
        try! fm.url(for: .applicationSupportDirectory, in: .userDomainMask, appropriateFor: nil, create: true)
    }()
    static let localStoreURL: URL = {
        appSupport.appendingPathComponent(STORE_NAME + ".sqlite")
    }()
}

extension PersistenceController {
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
                print("Database file copied to Application Suppor director")
            } catch {
                print("Error copying database file: \(error)")
                fatalError()
            }
        } else {
            print("Database file already exists in the documents directory at: ")
            print(destinationURL)
        }
    }
}
