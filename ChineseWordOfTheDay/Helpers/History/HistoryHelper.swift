import SwiftUI
import CoreData
import CoreDataModels

import SwiftUI
import CoreData
import CoreDataModels

import SwiftUI
import CoreData
import CoreDataModels

class HistoryHelper: ObservableObject {
    @Published var sections: [HistorySection] = []
    private let context: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func reload(groupingStyle: GroupingStyle = .month) {
        // 1. Fetch all WordStatus entries sorted by date
        let statusRequest: NSFetchRequest<WordStatus> = WordStatus.fetchRequest()
        statusRequest.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]
        
        do {
            let statusResults = try context.fetch(statusRequest)
            
            // 2. Extract unique traditional strings to fetch the actual 'Word' objects
            let allTraditionalStrings = Set(statusResults.map { $0.traditional })
            
            // 3. Batch Fetch all corresponding Words in ONE database hit
            let wordRequest: NSFetchRequest<Word> = Word.fetchRequest()
            wordRequest.predicate = NSPredicate(format: "traditional IN %@", allTraditionalStrings)
            let wordResults = try context.fetch(wordRequest)
            
            // 4. Create a Lookup Dictionary [TraditionalString : Word] for O(1) access
            let wordLookup = Dictionary(uniqueKeysWithValues: wordResults.map { ($0.traditional, $0) })
            
            // 5. Group the WordStatus results using your computed properties
            let groupedDict = Dictionary(grouping: statusResults) { $0.monthSection }
            
            // 6. Map to CardData by joining the Status and the Looked-up Word
            let rawSections = groupedDict.map { (title, statuses) in
                let cards = statuses.compactMap { status -> CardData? in
                    // Find the matching word in our pre-fetched dictionary
                    guard let matchedWord = wordLookup[status.traditional] else { return nil }
                    return CardData(status: status, word: matchedWord)
                }
                return HistorySection(title: title, cards: cards)
            }
            
            // 7. Final Sort for sections
            self.sections = rawSections.sorted { sectionA, sectionB in
                let dateA = (statusResults.first { $0.monthSection == sectionA.title })?.lastModified ?? Date.distantPast
                let dateB = (statusResults.first { $0.monthSection == sectionB.title })?.lastModified ?? Date.distantPast
                return dateA > dateB
            }
            
        } catch {
            print("Batch Fetch Failed: \(error)")
        }
    }
}
