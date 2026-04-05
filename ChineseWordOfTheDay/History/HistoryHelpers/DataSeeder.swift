import Foundation
import CoreData
import CoreDataModels

struct DictionaryMetadata {
    static let maxIndex: Int64 = 13810
    static let startingBuffer: Int64 = 100
    static let startIndex: Int64 = maxIndex - startingBuffer
}
struct DataSeeder {
    /// This wipes everything, seeds the history up to 13,790,
    static func seedMockHistory(context: NSManagedObjectContext) {
        let entities = ["WordStatus", "WordIndex"]
        for entity in entities {
            let fetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: entity)
            let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
            _ = try? context.execute(deleteRequest)
        }
        print("🧹 Existing history and index wiped. Starting fresh...")
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        let now = Date()
        // Spread the 13k+ words over the last 28 months
        var baseDate = calendar.date(byAdding: .month, value: -28, to: now) ?? now
        // This makes the History View look like you've been a legend for 2 years.
        print("🏗️ Seeding 13,790 history entries... hang tight.")
        for i in 1...Int(DictionaryMetadata.startIndex) {
            let status = WordStatus(context: context)
            status.index = Int64(i)
            status.status = 2 // Set to "Mastered"
            if i % 500 == 0 {
                baseDate = calendar.date(byAdding: .month, value: 1, to: baseDate) ?? now
            }
            // Add some "Jitter" so they aren't all on the same day
            let dayJitter = Int.random(in: 0...27)
            let hourJitter = Int.random(in: 0...23)
            
            if let finalDate = calendar.date(byAdding: .day, value: dayJitter, to: baseDate),
               let fullDate = calendar.date(byAdding: .hour, value: hourJitter, to: finalDate) {
                status.lastModified = fullDate
                status.sectionIdentifier = formatter.string(from: fullDate)
            } else {
                status.lastModified = baseDate
                status.sectionIdentifier = formatter.string(from: baseDate)
            }
        }
        // This sets the app's internal "pointer" to 13,790.
        let wordIndex = WordIndex(context: context)
        wordIndex.current = DictionaryMetadata.startIndex
        wordIndex.lastModified = now
        
        print("🎯 WordIndex pointer set to \(DictionaryMetadata.startIndex).")

        // 4. 💾 SAVE TO DISK
        do {
            try context.save()
            print("✅ SEED COMPLETE: 13,790 words in history. 20 words remaining.")
            print("📅 Range: \(formatter.string(from: calendar.date(byAdding: .month, value: -28, to: now)!)) -> NOW")
        } catch {
            print("❌ SEEDING FAILED: \(error)")
        }
    }
}

// MARK: - WORD INDEX LOGIC
extension WordIndex {
    static func pushToNextWord(context: NSManagedObjectContext) -> Int64 {
        let fetchRequest: NSFetchRequest<WordIndex> = WordIndex.fetchRequest()
        
        do {
            let results = try context.fetch(fetchRequest)
            let wordIndex = results.first ?? WordIndex(context: context)
            
            if wordIndex.current < DictionaryMetadata.maxIndex {
                wordIndex.current += 1
                wordIndex.lastModified = Date()
                try context.save()
                print("🚀 Pushed to index: \(wordIndex.current)")
            } else {
                print("🏁 Maximum dictionary index reached: \(DictionaryMetadata.maxIndex)")
            }
            return wordIndex.current
            
        } catch {
            print("❌ Push failed: \(error)")
            return DictionaryMetadata.startIndex // Fallback
        }
    }
}
