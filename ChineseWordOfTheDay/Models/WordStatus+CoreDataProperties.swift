//
//  WordStatus+CoreDataProperties.swift
//  WordFramework
//
//  Created by m on 12/11/23.
//
//

import Foundation
import CoreData


extension WordStatus {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WordStatus> {
        return NSFetchRequest<WordStatus>(entityName: "WordStatus")
    }
    @NSManaged public var status: Int64
    @NSManaged public var traditional: String?
    @NSManaged public var lastModified: Date?
}

extension WordStatus : Identifiable {

}
extension Word {
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
    func writeToUserDefaults() {
        let mockWord = self.toMockWord()
        if let encodedWord = try? JSONEncoder().encode(mockWord) {
            let sharedDefaults = UserDefaults(suiteName: Constants.appGroupId)
            sharedDefaults?.set(encodedWord, forKey: Constants.Defaults.mockWordKey)
        }
    }
}
