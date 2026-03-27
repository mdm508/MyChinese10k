//
//  CardData.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 3/27/26.
//
import CoreData
import Foundation
import CoreDataModels


enum GroupingStyle {
    case day
    case month
    case none
}

struct CardData: Identifiable, Equatable {
    let statusID: NSManagedObjectID
    var id: NSManagedObjectID { statusID }
    var wordIndex: Int64
    // UI Properties
    let characters: String
    let phonetic: String
    let status: Int64
    let meanings: [String]
    
    /// LITERATE NOTE:
    /// This property uses the already-filtered meanings from your Word extension.
    var displayMeaning: String {
        meanings.first ?? "No definition"
    }
    
    /// The Composite Initializer
    /// This pulls the 'content' from Word and 'metadata' from WordStatus.
    init(status: WordStatus, word: Word) {
        self.statusID = status.objectID
        self.status = status.status
        // Use 'characters' for the main display (horse, etc.)
        self.characters = word.characters
        self.phonetic = word.phonetic
        
        // Accessing the filtered meanings array you already built in the Word extension
        self.meanings = word.cleanedMeanings()
        self.wordIndex = word.index
    }
}

struct HistorySection: Identifiable {
    let id = UUID()
    let title: String
    let cards: [CardData]
}
