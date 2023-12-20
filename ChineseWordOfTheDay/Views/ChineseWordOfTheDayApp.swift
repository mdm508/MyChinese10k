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
    init(){
        PersistenceController.copyDatabaseIfNeeded()
        resetAllLocalStatus()
        Task(priority: .high){
//            await  deletAllCloudWordStatus()
//            print("Reset complete")
        }
        wordVM = WordViewModel(viewContext: PersistenceController.shared.context)

        if PersistenceController.isFirstRunOfApplication(){
            Task{
//                await updateAllLocalStatus()
//                PersistenceController.updateUserDefaultsToHasRunBefore()
            }
        } else {
            print("its not the first run")
        }
        setupCloudSub()
        appDelegate.delegate = wordVM
     
    }

}
extension ChineseWordOfTheDayApp {
    var body: some Scene {
        WindowGroup {
            //change this so its either a) loading type view if we are still syning to icloud
            //b) content view if not
            ContentView(viewModel: self.wordVM)
        }
    }
}
