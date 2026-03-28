import Foundation
import CoreData
import CoreDataModels

// MARK: - PHASE 1: DATA INGESTION

/// Maps JSON keys to Core Data attributes and ensures correct types.
func sanitizeJSON(_ json: [[String: Any]]) -> [[String: Any]] {
    return json.map { entry in
        [
            "zhuyin": entry["zhuyin"] as? String ?? "",
            "pinyin": entry["pinyin"] as? String ?? "",
            "traditional": entry["traditional"] as? String ?? "",
            "simplified": entry["simplified"] as? String ?? "",
            "meanings": entry["meanings"] as? [String] ?? [],
            "context": entry["context"] as? [String] ?? [],
            "index": Int64(entry["index"] as? Int ?? 0)
        ]
    }
}

/// Loads 'output.json' from the WordBuilder Resources folder.
public func loadWordsFromJson() -> [[String: Any]] {
    guard let url = Bundle.module.url(forResource: "output", withExtension: "json") else {
        fatalError("❌ JSON file 'output.json' not found in WordBuilder resources.")
    }
    do {
        let data = try Data(contentsOf: url)
        let json = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] ?? []
        return sanitizeJSON(json)
    } catch {
        fatalError("❌ Failed to parse JSON: \(error)")
    }
}

// MARK: - PHASE 2: CORE DATA STACK

/// Sets up a fresh, empty SQLite store in the temporary directory.
func createFreshContext() -> NSManagedObjectContext {
    print("------- 🏗️ PHASE 1: SETUP -------")
    
    let model = ModelLoader.loadModel()
    let psc = NSPersistentStoreCoordinator(managedObjectModel: model)
    
    // Create path for the temp DB
    let dbName = "\(ModelLoader.name).sqlite"
    let tempURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(dbName)
    
    // Clean up any old files from previous failed runs
    let fm = FileManager.default
    [tempURL.path, tempURL.path + "-wal", tempURL.path + "-shm"].forEach { try? fm.removeItem(atPath: $0) }

    do {
        try psc.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: tempURL, options: nil)
        print("✅ Created temporary store at: \(tempURL.path)")
    } catch {
        fatalError("❌ Could not create SQLite store: \(error)")
    }

    let context = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
    context.persistentStoreCoordinator = psc
    return context
}

// MARK: - PHASE 3: EXECUTION & EXPORT

/// Uses high-performance Batch Insert to seed the database.
func seedDatabase(using context: NSManagedObjectContext) {
    print("------- 🌱 PHASE 2: SEEDING -------")
    let entries = loadWordsFromJson()
    
    let batchRequest = NSBatchInsertRequest(entityName: "Word", objects: entries)
    batchRequest.resultType = .statusOnly
    
    do {
        let result = try context.execute(batchRequest) as? NSBatchInsertResult
        if let success = result?.result as? Bool, success {
            print("✅ Successfully seeded \(entries.count) entries.")
        }
    } catch {
        fatalError("❌ Batch insert failed: \(error)")
    }
}

/// Merges WAL logs and copies the final .sqlite file to your project directory.
func finalizeAndExport(from context: NSManagedObjectContext) {
    print("------- 📦 PHASE 3: EXPORT -------")
    guard let store = context.persistentStoreCoordinator?.persistentStores.first,
          let tempURL = store.url else { return }

    // Checkpoint: Merge WAL into the main SQLite file
    do {
        try context.persistentStoreCoordinator?.remove(store)
        let options = [NSSQLitePragmasOption: ["journal_mode": "DELETE"]]
        try context.persistentStoreCoordinator?.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: tempURL, options: options)
    } catch {
        fatalError("❌ Failed to merge WAL logs.")
    }
    
    // Destination (Change this path if you move your project)
    let destPath = "/Users/m/Developer/MyChinese10k/MYFrameworks/Persistence/\(ModelLoader.name).sqlite"
    let destURL = URL(fileURLWithPath: destPath)
    
    do {
        if FileManager.default.fileExists(atPath: destURL.path) {
            try FileManager.default.removeItem(at: destURL)
        }
        try FileManager.default.copyItem(at: tempURL, to: destURL)
        print("🎯 Final DB exported to: \(destPath)")
    } catch {
        fatalError("❌ Export failed: \(error)")
    }
}
