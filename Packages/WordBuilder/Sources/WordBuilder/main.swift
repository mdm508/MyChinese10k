//
//  main.swift
//  StoreBuilderMain
//
//  Created by m on 7/12/23.


import Foundation
import CoreDataModels
import CoreData

public func loadWordsFromJson() -> [[String: Any]] {
    guard let url = Bundle.module.url(forResource: "output", withExtension: "json") else {
        fatalError("JSON file not found in module bundle.")
    }
    do {
        let jsonData = try Data(contentsOf: url)
        let jsonEntries = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] ?? []
        return renameKeysInJSONData(jsonEntries)
    } catch {
        fatalError("Error loading JSON: \(error)")
    }
}

///: Load Json and  output array that will be able to be batch inserted from StoreBuilderMain
//public func loadWordsFromJson() -> [[String: Any]] {
//    guard let bundle = Bundle(identifier: "matthedm.DataStoreBuilder") else {
//        fatalError("could't locate bundle")
//    }
//    if let url = bundle.url(forResource: "output", withExtension: "json") {
//        do {
//            let jsonData = try Data(contentsOf: url)
//            let jsonEntries = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [[String: Any]] ?? []
//            return renameKeysInJSONData(jsonEntries)
//
//            
//        } catch let error as DecodingError {
//            print("Decoding error: \(error)")
//        } catch let error {
//            print("Error: \(error)")
//        }
//    } else {
//        fatalError("JSON file not found.")
//    }
//    return []
//}
func renameKeysInJSONData(_ jsonEntries: [[String: Any]]) -> [[String: Any]] {
    return jsonEntries.map { jsonEntry in
        return [
            "context": jsonEntry["context"]!,
            "zhuyin": jsonEntry["zhuyin"]!,
            "pinyin": jsonEntry["pinyin"]!,
            "traditional": jsonEntry["traditional"]!,
            "simplified": jsonEntry["simplified"]!,
            "meanings": jsonEntry["meanings"]!,
            "index": jsonEntry["index"]!,
        ]
    }
}
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
    print("hello boy")
    
    // Copy the existing database from MYFrameworks to Documents
    let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
    let destinationURL = documentsPath.appendingPathComponent("WordModel.sqlite")
    
    // Source database path
    let sourcePath = "/Users/m/Developer/MyChinese10k/MYFrameworks/Persistence/WordModel.sqlite"
    
    // Remove existing database if it exists
    if FileManager.default.fileExists(atPath: destinationURL.path) {
        try! FileManager.default.removeItem(at: destinationURL)
        print("🗑️ Removed existing database")
    }
    
    // Copy the database
    try! FileManager.default.copyItem(atPath: sourcePath, toPath: destinationURL.path)
    print("✅ Database copied successfully!")
    print("📁 Destination: \(destinationURL)")
    
    // Verify the copy
    let sourceSize = try! FileManager.default.attributesOfItem(atPath: sourcePath)[.size] as! Int64
    let destSize = try! FileManager.default.attributesOfItem(atPath: destinationURL.path)[.size] as! Int64
    
    if sourceSize == destSize {
        print("✅ File sizes match: \(sourceSize) bytes")
    } else {
        print("❌ File size mismatch! Source: \(sourceSize), Destination: \(destSize)")
    }
    
    print("🎯 Database is ready to be copied to your app!")
}
print("sup boy")
main()

/**
 Preloading the Core Data Store
 
 Follow these steps to preload your store:
 
 1. Turn off Write-Ahead Logging (WAL) mode:
    - Open a new terminal window.
    - Navigate to the location of your SQLite database:
      ```
      cd /Users/m/Library/Developer/CoreSimulator/Devices/7E299733-C694-4075-A063-39A8E0565A16/data/Containers/Data/Application/0D1DE818-FF74-4798-ACDD-D5F5B9B0087A/Library/Application
      ```
    - Access the SQLite database using the command:
      ```
      sqlite3 WordModel.sqlite
      ```
    - Turn off WAL mode with the command:
      ```
      PRAGMA journal_mode = DELETE;
             .quit
      ```
 
 2. Copy the WordModel.sqlite file into the project's Resource folder.
 
 3. Delete the old SQLite files inside the Application Support directory:
    - Navigate to the following location:
      ```
      /Users/m/Library/Developer/CoreSimulator/Devices/7E299733-C694-4075-A063-39A8E0565A16/data/Containers/Data/Application/6B452F81-979A-4CD1-80EA-113BF35355CB/Library/Application
      ```
 
 Make sure that WordModel.sqlite is included in the app target.
 */
