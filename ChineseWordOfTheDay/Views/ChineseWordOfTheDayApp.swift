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
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    init(){
//        deleteAll()
        PersistenceController.copyDatabaseIfNeeded()
            let appearance = UINavigationBarAppearance()
            appearance.configureWithDefaultBackground() // looks like classic UIKit
        appearance.backgroundColor = .systemBackground
            appearance.titleTextAttributes = [.foregroundColor: UIColor.label]
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
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
class AppDelegate: NSObject, UIApplicationDelegate {
    /// Handles app launch setup, including synchronizing iCloud Key-Value Store and setting default user preferences.
    /// - Note: iCloud sync may take a few seconds to propagate across devices.
    /// - Returns: `true` to indicate successful launch.
    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        /// Try
        NSUbiquitousKeyValueStore.default.synchronize()
        // If the app is launching for the first time or preferences are missing,
        // set the default values for user settings.
        if UserPreferences.areUnset() {
            Task { await UserPreferences.setAppDefaults()}
        }
        return true
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
