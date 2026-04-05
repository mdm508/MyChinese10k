//
//  ChineseWordOfTheDayApp.swift
//  ChineseWordOfTheDay
//
//  Created by m on 7/11/23.
//

import SwiftUI
import CoreData
import CoreDataModels
import UIKit
import CloudKit
import Persistence
import UserNotifications
import Combine

@main
struct ChineseWordOfTheDayApp: App {
    @StateObject var ws: WordService
    @StateObject var historyHelper: HistoryHelper

    @State private var ready = false
    @State private var p = PersistenceController.shared
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init(){
//        PersistenceController.shared.deleteAllCloud()
//        deleteDatabase()
//        DataSeeder.seedMockHistory(context: PersistenceController.shared.context)
        _ws = StateObject(wrappedValue: WordService(context: PersistenceController.shared.context))
        _historyHelper = StateObject(wrappedValue: HistoryHelper(context: PersistenceController.shared.context))
        
    }
}
extension ChineseWordOfTheDayApp {
    var body: some Scene {
        WindowGroup {
            Group {
                if p.isReady {
                    ContentView()
                    .environmentObject(ws)
                    .environmentObject(historyHelper) 
                    .environment(\.managedObjectContext, PersistenceController.shared.context)
                    .transition(.opacity)
                } else {
                    LoadingView()
                }
            }
        }
    }
}
