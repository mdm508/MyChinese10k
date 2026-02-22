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
    init(){
        PersistenceController.copyDatabaseIfNeeded()
        _ws = StateObject(wrappedValue: WordService(context: PersistenceController.shared.context))
    }
}
extension ChineseWordOfTheDayApp {
    var body: some Scene {
        WindowGroup {
            Group {
                    ContentView()
                    .environmentObject(ws)
                    .transition(.opacity)
            }
        }
    }
}
