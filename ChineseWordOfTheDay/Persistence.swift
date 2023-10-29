//
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

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: STORE_NAME)
        if inMemory {
            container.persistentStoreDescriptions.first!.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions.first!.setOption(true as NSNumber, forKey: NSPersistentHistoryTrackingKey)
        }
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            print(storeDescription.url)
            if let error = error as NSError? {
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        container.viewContext.automaticallyMergesChangesFromParent = true
    }
}

extension PersistenceController {
    /// Ensures that when application is first run, a preloaded database will be copied into the Sandbox.
    /// For this function to work correctly, it must be that the store was previously set to journal mode.
    /// I did this by executing the sql command 'PRAGMA journal_mode = delete;' on the store.
    static func copyDatabaseIfNeeded() {
        let fileManager = FileManager.default
        guard let bundlePath = Bundle.main.path(forResource: STORE_NAME, ofType: "sqlite") else {
            print("Database file not found in the app bundle.")
            return
        }
        guard let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("Unable to access the documents directory.")
            return
        }
        let destinationURL = appSupport.appendingPathComponent(STORE_NAME + ".sqlite")
        // is the store already in documents? if so we dont need to copy it
        if !fileManager.fileExists(atPath: destinationURL.path) {
            do {
                try fileManager.copyItem(atPath: bundlePath, toPath: destinationURL.path)
                print("Database file copied to documents directory.")
            } catch {
                print("Error copying database file: \(error)")
            }
        } else {
            print("Database file already exists in the documents directory at: ")
            print(destinationURL)
        }
    }
    
}

extension PersistenceController {
//    func longestWord() -> Word {
//        
//        
//    }
}


