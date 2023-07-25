//
//  main.swift
//  StoreBuilderMain
//
//  Created by m on 7/12/23.
//

import Foundation
import DataStoreBuilder
import WordFramework
import CoreData


func printStoreLocation(container:NSPersistentContainer){
    // Get the URL of the persistent store file
    guard let storeURL = container.persistentStoreCoordinator.persistentStores.first?.url else {
        fatalError("Unable to retrieve the persistent store URL")
    }
    var path = storeURL.standardizedFileURL.pathComponents
    path = path.dropLast()
    path[0] = ""
    print("db files are at: ")
    print(path.joined(separator: "/"))
}

func main() {
    // Setup Persistent Container
    let container = NSPersistentContainer(name: STORE_NAME)
    container.loadPersistentStores { (_, error) in
        if let error = error as NSError? {
            fatalError("Failed to load persistent stores: \(error), \(error.userInfo)")
        }
        // Load words from json then save to container
        let words = loadWordsFromJson()
        let context = container.viewContext
        let request = NSBatchInsertRequest(entityName: "Word", objects: words)
        print(words[0].keys)
        printStoreLocation(container: container)
        try! context.execute(request)
        try! context.save()
    }
}

main()

/*
 turn off wal mode
 cd /Users/m/Library/Application\ Support/setup/
 sqlite3 PersonDemo.sqlite
 PRAGMA journal_mode = DELETE;
 */
