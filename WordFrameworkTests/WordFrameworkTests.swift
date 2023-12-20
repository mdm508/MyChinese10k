//
//  WordFrameworkTests.swift
//  WordFrameworkTests
//
//  Created by m on 7/11/23.
//

import XCTest
import CoreData

final class WordFrameworkTests: XCTestCase {
    var persistentContainer: NSPersistentContainer!

    override func setUpWithError() throws {
        super.setUp()
        persistentContainer = NSPersistentContainer(name: "WordModel") // Replace with your actual Core Data model name
        let description = NSPersistentStoreDescription()
        
        description.type = NSInMemoryStoreType
        persistentContainer.persistentStoreDescriptions = [description]
        persistentContainer.loadPersistentStores { _, error in
            XCTAssertNil(error, "Failed to load the persistent store: \(error!)")
        }
    }

    override func tearDownWithError() throws {
        persistentContainer = nil
        super.tearDown()
    }

    func testCoreDataStoreConnectivity() throws {
        let context = persistentContainer.viewContext

        let fetchRequest: NSFetchRequest<Word> = Word.fetchRequest()
        let fetchedWords = try context.fetch(fetchRequest)
        XCTAssertTrue(fetchedWords.isEmpty, "The Core Data store should be empty initially.")
        
        // Perform other tests or assertions related to the Core Data store connectivity
        // For example, you can test inserting, fetching, or modifying objects in the store
        // using the 'context' instance.
    }

}
