import CoreData
import Foundation
import CoreDataModels

struct CardData: Identifiable, Equatable {
    let id: NSManagedObjectID
    
    // Metadata
    let lastModified: Date
    let masteryStatus: Int64
    
    // Content
    let wordIndex: Int64
    let characters: String
    let phonetic: String
    let meanings: [String]
    
    // --- 🏷️ NEW FOR HISTORY FILTERING ---
    /// Returns a string like "August 2025" for grouping in History
    var monthTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: lastModified)
    }

    // Computed helper for the UI
    var displayMeaning: String {
        meanings.first ?? ""
    }
    
    // UI State (Not persisted, just for the session)
    var isFlipped: Bool = false
    
    init(status: WordStatus, word: Word) {
        self.id = status.objectID
        
        // Capture the timestamp for "Recent" sorting
        self.lastModified = status.lastModified ?? Date.distantPast
        self.masteryStatus = status.status
        
        // Capture Word content
        self.characters = word.characters ?? ""
        self.phonetic = word.phonetic ?? ""
        self.wordIndex = word.index
        
        // Use the Word extension method for clean meanings
        self.meanings = word.cleanedMeanings()
    }
    
    // Equatable conformance
    static func == (lhs: CardData, rhs: CardData) -> Bool {
        lhs.id == rhs.id &&
        lhs.lastModified == rhs.lastModified &&
        lhs.masteryStatus == rhs.masteryStatus
    }
}
