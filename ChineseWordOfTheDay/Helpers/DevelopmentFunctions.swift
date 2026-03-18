//
//  DevelopmentFunctions.swift
//  ChineseWordOfTheDay
//
//  Created by m on 12/14/23.
//

import Foundation
import CloudKit
import CoreData
import CoreDataModels
import Persistence


/*
 Development reminder:
 call this after changing the Core Data model if the local store
 was created from an older schema.

 This removes the old local SQLite files so the next launch can
 build a fresh store from the current model instead of trying to
 load a stale or incompatible one.
*/
public func deleteDatabase() {
    let fm = FileManager.default
    let storeURL = PersistenceController.appGroupURL
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
    print("Deleted \(storeURL.absoluteString) database. Restart the app to use it.")
    exit(0)
}
