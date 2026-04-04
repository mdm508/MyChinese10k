import CoreData
import Foundation
import CoreDataModels

struct DataSeeder {
    static func seedMockHistory(context: NSManagedObjectContext) {
        // 1. Wipe existing statuses
        let fetchRequest: NSFetchRequest<NSFetchRequestResult> = WordStatus.fetchRequest()
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        _ = try? context.execute(deleteRequest)
        
        print("🧹 Existing history wiped.")

        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM" // Matches your HistoryHelper logic
        
        let now = Date()
        // Start ~28 months ago to spread out 13.8k words
        var baseDate = calendar.date(byAdding: .month, value: -28, to: now) ?? now

        // 2. The Big Loop
        for i in 1...13810 {
            let status = WordStatus(context: context)
            
            status.index = Int64(i)
            status.status = 2 // All set to mastered/seen
            
            // Increment month every 500 words
            if i % 500 == 0 {
                baseDate = calendar.date(byAdding: .month, value: 1, to: baseDate) ?? now
            }
            
            // Randomize the specific day/time within that month block
            let dayJitter = Int.random(in: 0...27)
            let hourJitter = Int.random(in: 0...23)
            
            if let finalDate = calendar.date(byAdding: .day, value: dayJitter, to: baseDate),
               let fullDate = calendar.date(byAdding: .hour, value: hourJitter, to: finalDate) {
                
                status.lastModified = fullDate
                // ✅ CRITICAL: Set the section identifier for the FRC
                status.sectionIdentifier = formatter.string(from: fullDate)
            } else {
                status.lastModified = baseDate
                status.sectionIdentifier = formatter.string(from: baseDate)
            }
        }

        // 3. Save to Disk
        do {
            try context.save()
            print("✅ 13,810 WordStatuses seeded with Section Identifiers.")
            print("📅 Test range: \(formatter.string(from: calendar.date(byAdding: .month, value: -28, to: now)!)) to \(formatter.string(from: now))")
        } catch {
            print("❌ Seeding failed: \(error)")
        }
    }
}
