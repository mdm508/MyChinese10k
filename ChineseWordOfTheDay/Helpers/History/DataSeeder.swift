import CoreData
import CoreDataModels

struct DataSeeder {
    static func seedMockHistory(context: NSManagedObjectContext) {
        // 1. Wipe existing statuses for a clean test run
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: WordStatus.fetchRequest())
        _ = try? context.execute(deleteRequest)
        
        // 2. Fetch Words (Filtered for valid characters)
        let wordRequest: NSFetchRequest<Word> = Word.fetchRequest()
        wordRequest.predicate = NSPredicate(format: "index <= 13810 AND traditional != nil AND traditional != ''")
        wordRequest.sortDescriptors = [NSSortDescriptor(key: "index", ascending: true)]
        
        // Limit to 1000 for a solid performance test
        wordRequest.fetchLimit = 13810

        do {
            let words = try context.fetch(wordRequest)
            print("📦 Found \(words.count) valid words to seed.")

            let calendar = Calendar.current
            let now = Date()
            var currentDate = calendar.date(byAdding: .month, value: -10, to: now) ?? now
            var seededChars = Set<String>()

            // 3. Batch Create Statuses
            for (i, word) in words.enumerated() {
                let char = word.traditional
                
                if char.isEmpty || seededChars.contains(char) { continue }
                seededChars.insert(char)

                let status = WordStatus(context: context)
                status.traditional = char
                status.status = Int64.random(in: 1...5)
                
                // ⚠️ COMMENTED OUT until you add 'wordIndex' to the .xcdatamodeld file
                // status.wordIndex = word.index
                
                // Date clustering logic
                if i % 40 == 0 {
                    currentDate = calendar.date(byAdding: .day, value: 14, to: currentDate) ?? now
                }
                
                let jitter = Int.random(in: -3600...3600)
                status.lastModified = calendar.date(byAdding: .second, value: jitter, to: currentDate)
            }

            try context.save()
            print("✅ Successfully seeded \(seededChars.count) unique WordStatuses.")
            
        } catch {
            print("❌ Seeding failed: \(error)")
        }
    }
}
