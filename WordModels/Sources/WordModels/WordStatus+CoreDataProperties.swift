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
    @NSManaged var traditional: String?
    @NSManaged var lastModified: Date?
}

extension WordStatus : Identifiable {

}
public extension Word {
    func toMockWord() -> MockWord {
        return MockWord(
            context: self.context,
            frequency: self.frequency,
            index: self.index,
            level: self.level,
            meanings: self.meanings,
            pinyin: self.pinyin,
            simplified: self.simplified,
            spokenFrequency: self.spokenFrequency,
            traditional: self.traditional,
            writtenFrequency: self.writtenFrequency,
            zhuyin: self.zhuyin,
            synonyms: self.synonyms,
            status: self.status
        )
    }
    /// Writes self to user defaults.
    /// - Parameters:
    ///   - appGroupId:
    ///   - mockWordKey:
    func writeToUserDefaults(appGroupId: String=Constants.appGroupId,
                             mockWordKey: String=Constants.mockWordKey) {
        let mockWord = self.toMockWord()
        if let encodedWord = try? JSONEncoder().encode(mockWord) {
            let sharedDefaults = UserDefaults(suiteName: appGroupId)
            sharedDefaults?.set(encodedWord, forKey: mockWordKey)
        }
    }
}
