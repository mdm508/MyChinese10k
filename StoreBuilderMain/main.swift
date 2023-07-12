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


func main() {
    // Setup Persistent Container
    let container = NSPersistentContainer(name: STORE_NAME)
    container.loadPersistentStores { (_, error) in
        if let error = error as NSError? {
            fatalError("Failed to load persistent stores: \(error), \(error.userInfo)")
        }
    }
    // Load words from json then save to container
    let words = loadWordsFromJson()
    let request = NSBatchInsertRequest(entityName: "Word", objects: words)
    request.resultType = .count
    do {
        try container.viewContext.execute(request)
        try container.viewContext.save()
    } catch {
        fatalError(error.localizedDescription)
    }
    // Get the URL of the persistent store file
    guard let storeURL = container.persistentStoreCoordinator.persistentStores.first?.url else {
        fatalError("Unable to retrieve the persistent store URL")
    }
    var path = storeURL.standardizedFileURL.pathComponents
    path = path.dropLast()
    path[0] = ""
    print("db files are at: ")
    print(path.joined(separator: "/"))

//        // Get what DB contains
//        let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
//
//        do {
//            let word = try container.viewContext.fetch(fetchRequest)
//
//            for word in words {
//                print(word)
//                print("--------------")
//            }
//        } catch {
//            print("Error fetching people: \(error.localizedDescription)")
//        }
}

main()
