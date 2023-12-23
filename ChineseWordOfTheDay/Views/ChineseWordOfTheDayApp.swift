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
            await  deletAllCloudWordStatus()
            print("Reset complete")
        }
//        //TESTING
//        // put testing stuff here
//        if let words = WordStatus.fetchSeenAndKnown(context: PersistenceController.shared.context){
//            for x in words{
//                print(x.traditional, x.status)
//            }
//        }
//        print("now we get words not on the cloud")
//        if let words = Word.fetchHigestPriorityUnseenWord(context: PersistenceController.shared.context){
//            for x in words {
//                print(x.traditional, x.status)
//            }
//        }
//            //       try! PersistenceController.shared.context.save()
//        print("done")
        
        

        wordVM = WordViewModel(viewContext: PersistenceController.shared.context)

        if PersistenceController.isFirstRunOfApplication(){
            Task{
//                await updateAllLocalStatus()
//                PersistenceController.updateUserDefaultsToHasRunBefore()
            }
        } else {
            print("its not the first run")
        }
//        setupCloudSub()
        appDelegate.delegate = wordVM
        PersistenceController.shared.delegate = wordVM

        
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
