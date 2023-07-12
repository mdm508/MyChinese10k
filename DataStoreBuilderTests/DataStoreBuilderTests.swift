//
//  DataStoreBuilderTests.swift
//  DataStoreBuilderTests
//
//  Created by m on 7/11/23.
//

import XCTest
import WordFramework
import CoreData
@testable import DataStoreBuilder

class DataStoreBuilderTests: XCTestCase {
    let totalWords = 13829

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testLoadedAll() throws {
        let words = loadWordsFromJson()
        XCTAssertEqual(words.count, totalWords)
        
    }



}
