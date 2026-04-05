//
//  CardData.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 3/27/26.
//
import CoreData
import Foundation
import CoreDataModels


struct CardData: Identifiable, Equatable {
    let id: NSManagedObjectID // Directly using the Core Data ID
    // Metadata (from WordStatus)
    let lastModified: Date
    let masteryStatus: Int64
    // Content (from Word)
    let wordIndex: Int64
    let characters: String
    let phonetic: String
    let meanings: [String]
    // Computed helper for the UI
    var displayMeaning: String {
        meanings.first ?? ""
    }
    // Needed by the view to determine which side of the card to show.
    var isFlipped: Bool = false
    init(status: WordStatus, word: Word) {
        // 1. Link the ID
        self.id = status.objectID
        
        // 2. Capture the timestamp for "Recent" sorting
        // We fallback to distantPast so nil dates don't break the sort
        self.lastModified = status.lastModified ?? Date.distantPast
        self.masteryStatus = status.status
        
        // 3. Capture Word content
        self.characters = word.characters
        self.phonetic = word.phonetic
        self.wordIndex = word.index
        
        // 4. Use your existing Word extension method for clean meanings
        self.meanings = word.cleanedMeanings()
    }
    // Equatable conformance to help SwiftUI animate moves/shuffles
    static func == (lhs: CardData, rhs: CardData) -> Bool {
        lhs.id == rhs.id &&
        lhs.lastModified == rhs.lastModified &&
        lhs.masteryStatus == rhs.masteryStatus
    }
}
