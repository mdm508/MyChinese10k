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

@main
struct ChineseWordOfTheDayApp: App {
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init(){
//        deleteAll()
        PersistenceController.copyDatabaseIfNeeded()
//        appDelegate.delegate = wordVM
    }
} 
extension ChineseWordOfTheDayApp {
    var body: some Scene {
        WindowGroup {
            ContentView().environment(\.managedObjectContext, PersistenceController.shared.context)
        }
    }
}

//class AppDelegate: NSObject, UIApplicationDelegate {
//    var delegate: CurrentWordRefreshDelegate?
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        application.registerForRemoteNotifications()
//        return true
//    }
//    
//    func application(_ application: UIApplication,
//                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
//                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        // Convert the remote notification payload into a CKNotification
//        if let d = self.delegate {
//            if let wordInfo = extractCloudKitInfo(from:userInfo){ // this is the word received from remote
//                updateLocalStatus(with: wordInfo)
//                d.refresh()
//            }
//        }
//        completionHandler(.newData)
//    }
//
//    //    /// If this WordStatus exists twice on the cloud and delete the older one
//    //    func deduplicate(cloudNotifactionInfo: CloudKitNotificationInfo) -> CloudKitNotificationInfo {
//    //        return cloudNotifactionInfo
//    //    }
//}
