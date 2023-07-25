//
//  ChineseWordOfTheDayApp.swift
//  ChineseWordOfTheDay
//
//  Created by m on 7/11/23.
//

import SwiftUI
import CoreData
import WordFramework
@main
struct ChineseWordOfTheDayApp: App {
    init(){
        let container = NSPersistentContainer(name: STORE_NAME)
        container.loadPersistentStores { (_, error) in
            if let error = error as NSError? {
                fatalError("Failed to load persistent stores: \(error), \(error.userInfo)")
            }
        }

    }
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
