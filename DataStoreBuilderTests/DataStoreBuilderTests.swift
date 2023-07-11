//
//  DataStoreBuilderTests.swift
//  DataStoreBuilderTests
//
//  Created by m on 7/11/23.
//

import XCTest
@testable import DataStoreBuilder

class DataStoreBuilderTests: XCTestCase {
    let totalWords = 14425
    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testLoadedAll() throws {
        let words = loadWordsFromJson(limit: 10)
        for x in words {
            print(x)
        }
        XCTAssertEqual(words.count, 10)
        
    }

    func testMain() throws {
        print("hi")
    }


}
