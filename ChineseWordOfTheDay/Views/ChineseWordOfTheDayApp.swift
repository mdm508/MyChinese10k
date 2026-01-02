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

@main
struct ChineseWordOfTheDayApp: App {
    init(){
        PersistenceController.copyDatabaseIfNeeded()
    }
}
extension ChineseWordOfTheDayApp {
    var body: some Scene {
        WindowGroup {
            Group {
                    ContentView()
                        .environment(\.managedObjectContext, PersistenceController.shared.context)
                        .transition(.opacity)
            }
        }
    }
}
