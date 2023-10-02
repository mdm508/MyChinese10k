//
//  Word+CoreDataProperties.swift
//  WordFramework
//
//  Created by m on 7/11/23.
//
//

import Foundation
import CoreData


extension Word {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Word> {
        return NSFetchRequest<Word>(entityName: "Word")
    }

    @NSManaged public var my_context: String
    @NSManaged public var my_frequency: Int64
    @NSManaged public var my_index: Int64
    @NSManaged public var my_level: Double
    @NSManaged public var my_meanings: [String]
    @NSManaged public var my_pinyin: String
    @NSManaged public var my_simplified: String
    @NSManaged public var my_spokenFrequency: Int64
    @NSManaged public var my_traditional: String
    @NSManaged public var my_writtenFrequency: Int64
    @NSManaged public var my_zhuyin: String
    @NSManaged public var my_synonyms: [String]

}

extension Word : Identifiable {

}

//extension Word {
//    static func longestWordsFetchRequest() -> NSFetchRequest<Word> {
//        let request: NSFetchRequest<Word> = Word.fetchRequest()
//        let descriptor = NSSortDescriptor(keyPath: Word\.frequency, ascending: true){
//            (w1, w2) in
//            
//        }
//        request.sortDescriptors = []
//    }
//}
