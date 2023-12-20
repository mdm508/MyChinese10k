//
//  ChineseWordOfTheDayTests.swift
//  ChineseWordOfTheDayTests
//
//  Created by m on 12/16/23.
//

import XCTest
import ChineseWordOfTheDay


final class ChineseWordOfTheDayTests: XCTestCase {

    override func setUpWithError() throws {
        PersistenceController.copyDatabaseIfNeeded()
        resetAllLocalStatus()
        Task(priority: .high){
            await  deletAllCloudWordStatus()
            print("Reset complete")
        }
        wordVM = WordViewModel(viewContext: PersistenceController.shared.context)

    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
        // Any test you write for XCTest can be annotated as throws and async.
        // Mark your test throws to produce an unexpected failure when your test encounters an uncaught error.
        // Mark your test async to allow awaiting for asynchronous code to complete. Check the results with assertions afterwards.
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}
