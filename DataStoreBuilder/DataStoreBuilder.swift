//
//  DataStoreBuilder.swift
//  DataStoreBuilder
//
//  Created by m on 7/11/23.
//

import Foundation
import WordFramework

func loadWordsFromJson(limit: Int = 0) -> [Word] {
    guard let bundle = Bundle(identifier: "matthedm.DataStoreBuilder") else {
        fatalError("could't locate bundle")
    }
    if let url = bundle.url(forResource: "output", withExtension: "json") {
        do {
            let jsonData = try Data(contentsOf: url)
            let decoder = JSONDecoder()
//            let words = try decoder.decode([Word].self, from: jsonData)
            
            var words: [Word] = []
            let jsonEntries = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] ?? []
            
            
            for jsonEntry in jsonEntries {
                if (words.count >= limit){
                    return words
                }
                do {
                    let wordData = try JSONSerialization.data(withJSONObject: jsonEntry, options: [])
                    let word = try decoder.decode(Word.self, from: wordData)
                    words.append(word)
                } catch {
                    // Handle decoding error for individual word entry
                    print("Error decoding word: \(error)")
                }
            }
            if limit > 0{
                assert(limit < words.count)
                let amountToDrop = words.count - limit
                return words.dropLast(amountToDrop)
            }
            return words
            
        } catch let error as DecodingError {
            // Handle decoding errors
            print("Decoding error: \(error)")
        } catch let error {
            // Handle other errors
            print("Error: \(error)")
        }
    } else {
        print("JSON file not found.")
    }
    return []
}
