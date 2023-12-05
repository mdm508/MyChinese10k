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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let wordVM: WordViewModel
    init(){
        PersistenceController.copyDatabaseIfNeeded()
        setupCloudSub()
        wordVM = WordViewModel(viewContext: PersistenceController.shared.context)
        appDelegate.delegate = wordVM
    }
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: self.wordVM)
        }
    }
}
