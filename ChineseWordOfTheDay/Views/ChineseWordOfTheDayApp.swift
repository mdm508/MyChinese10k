//
//  ChineseWordOfTheDayApp.swift
//  ChineseWordOfTheDay
//
//  Created by m on 7/11/23.
//

import SwiftUI
import CoreData


@main
struct ChineseWordOfTheDayApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    let wordVM: WordViewModel
    /// On first run will bring the local database into the application.
    init(){
        PersistenceController.copyDatabaseIfNeeded()
        wordVM = WordViewModel(viewContext: PersistenceController.shared.context)
        appDelegate.delegate = wordVM
        PersistenceController.shared.delegate = wordVM
    }

}
extension ChineseWordOfTheDayApp {
    var body: some Scene {
        WindowGroup {
            ContentView(viewModel: self.wordVM)
        }
    }
}
