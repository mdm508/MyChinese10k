//
//  DataStoreBuilder.swift
//  DataStoreBuilder
//
//  Created by m on 7/11/23.
//

import Foundation
import WordFramework

///: Load Json and  output array that will be able to be batch inserted from StoreBuilderMain
public func loadWordsFromJson() -> [[String: Any]] {
    guard let bundle = Bundle(identifier: "matthedm.DataStoreBuilder") else {
        fatalError("could't locate bundle")
    }
    if let url = bundle.url(forResource: "output", withExtension: "json") {
        do {
            let jsonData = try Data(contentsOf: url)
            let jsonEntries = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] ?? []
            return renameKeysInJSONData(jsonEntries)

            
        } catch let error as DecodingError {
            print("Decoding error: \(error)")
        } catch let error {
            print("Error: \(error)")
        }
    } else {
        fatalError("JSON file not found.")
    }
    return []
}
func renameKeysInJSONData(_ jsonEntries: [[String: Any]]) -> [[String: Any]] {
    return jsonEntries.map { jsonEntry in
        return [
            "my_context": jsonEntry["context"]!,
            "my_frequency": jsonEntry["frequency"]!,
            "my_index": jsonEntry["index"]!,
            "my_level": jsonEntry["level"]!,
            "my_meanings": jsonEntry["meanings"]!,
            "my_pinyin": jsonEntry["pinyin"]!,
            "my_simplified": jsonEntry["simplified"]!,
            "my_spokenFrequency": jsonEntry["spokenFrequency"]!,
            "my_traditional": jsonEntry["traditional"]!,
            "my_writtenFrequency": jsonEntry["writtenFrequency"]!,
            "my_zhuyin": jsonEntry["zhuyin"]!
        ]
    }
}
