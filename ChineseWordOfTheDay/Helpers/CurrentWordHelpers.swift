////
////  CurrentWordViewModel.swift
////  ChineseWordOfTheDay
////
////  Created by m on 10/28/23.
////
//

import CoreDataModels
import CoreData
import Persistence

func updateCurrentWordStatusToSeen(word: Word, context: NSManagedObjectContext) async {
    Task{
        try await createCloudKitRecord(for: word)
    }
    do {
        try context.save()
        
    } catch {
        print("Error saving changes: \(error)")
    }
}
func incrementWordIndex(wordIndex: WordIndex, context: NSManagedObjectContext) {
    wordIndex.current += 1
    try! context.save()
}

