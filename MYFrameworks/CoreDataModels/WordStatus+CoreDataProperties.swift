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
    /** Dynamically provides a section identifier based on the user's current preference.
     This is used as the 'sectionNameKeyPath' in the FRC.
     */
    @objc public var monthSection: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy" // e.g., "October 2023"
        return formatter.string(from: lastModified ?? Date())
    }
    
    @objc public var weekSection: String {
        let calendar = Calendar.current
        let week = calendar.component(.weekOfYear, from: lastModified ?? Date())
        let year = calendar.component(.year, from: lastModified ?? Date())
        return "Week \(week), \(year)"
    }
}
