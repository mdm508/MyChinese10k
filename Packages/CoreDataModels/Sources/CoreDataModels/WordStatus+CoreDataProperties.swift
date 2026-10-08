//
//  WordStatus+CoreDataProperties.swift
//  CoreDataModels
//
//  Created by Matthew McLaughlin on 4/3/26.
//
//

public import Foundation
public import CoreData


public typealias WordStatusCoreDataPropertiesSet = NSSet

extension WordStatus {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WordStatus> {
        return NSFetchRequest<WordStatus>(entityName: "WordStatus")
    }

    @NSManaged public var lastModified: Date?
    @NSManaged public var status: Int64
    @NSManaged public var sectionIdentifier: String?
    @NSManaged public var index: Int64

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
