//
//  WordStatus+CoreDataProperties.swift
//  WordFramework
//
//  Created by m on 12/11/23.
//
//

import Foundation
import CoreData


public extension WordStatus {
    @nonobjc class func fetchRequest() -> NSFetchRequest<WordStatus> {
        return NSFetchRequest<WordStatus>(entityName: "WordStatus")
    }
    @NSManaged var status: Int64
    @NSManaged var traditional: String
    @NSManaged var lastModified: Date?
}

extension WordStatus : Identifiable {

}
public extension Word {
    func toMockWord() -> MockWord {
        return MockWord(
            index: self.index,
            context: self.context,
            meanings: self.meanings,
            pinyin: self.pinyin,
            simplified: self.simplified,
            traditional: self.traditional,
            zhuyin: self.zhuyin,
            characters: self.characters,
            phonetic: self.phonetic
            )
    }
    /// Writes self to user defaults.
    /// - Parameters:
    ///   - appGroupId:
    ///   - mockWordKey:
    func writeToUserDefaults() {
        let mockWord = self.toMockWord()
        if let encodedWord = try? JSONEncoder().encode(mockWord) {
            let sharedDefaults = UserDefaults(suiteName: Constants.appGroupId)
            sharedDefaults?.set(encodedWord, forKey: Constants.mockWordKey)
        }
    }
}
extension WordStatus {
    
    private static let dayFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        df.doesRelativeDateFormatting = true
        return df
    }()
    
    private static let monthFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        return df
    }()

    @objc public var daySection: String {
        return Self.dayFormatter.string(from: lastModified ?? Date())
    }

    @objc public var monthSection: String {
        return Self.monthFormatter.string(from: lastModified ?? Date())
    }
    
    @objc public var weekSection: String {
        let calendar = Calendar.current
        let date = lastModified ?? Date()
        
        // Find the start and end of the week for a better UI string
        if let weekInterval = calendar.dateInterval(of: .weekOfYear, for: date) {
            let start = Self.dayFormatter.string(from: weekInterval.start)
            let end = Self.dayFormatter.string(from: calendar.date(byAdding: .day, value: -1, to: weekInterval.end) ?? weekInterval.end)
            return "\(start) - \(end)"
        }
        
        // Fallback to simple week number if interval fails
        let week = calendar.component(.weekOfYear, from: date)
        let year = calendar.component(.year, from: date)
        return "Week \(week), \(year)"
    }
}
