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
    let persistenceController: PersistenceController
    init(){
        PersistenceController.copyDatabaseIfNeeded()
        persistenceController =  PersistenceController.shared
    }
    var body: some Scene {
        WindowGroup {
                ContentView()
                .environment(\.managedObjectContext,
                              persistenceController.container.viewContext)
        }
    }
}
