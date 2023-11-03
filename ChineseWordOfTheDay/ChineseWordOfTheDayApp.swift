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
        PersistenceController.copyDatabaseIfNeeded()
    }
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: WordViewModel(viewContext: PersistenceController.shared.context))
        }
    }
}
