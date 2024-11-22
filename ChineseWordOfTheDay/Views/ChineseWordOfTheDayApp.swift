//
//  ChineseWordOfTheDayApp.swift
//  ChineseWordOfTheDay
//
//  Created by m on 7/11/23.
//

import SwiftUI
import CoreData
import WordModels
import UIKit

@main
struct ChineseWordOfTheDayApp: App {
    let wordVM: WordViewModel
    /// On first run will bring the local database into the application.
    init(){
        PersistenceController.copyDatabaseIfNeeded()
        wordVM = WordViewModel(viewContext: PersistenceController.shared.context)
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
//
///*
// Why do you need this?
// */
//extension AppDelegate {
//    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
//        application.registerForRemoteNotifications()
//        return true
//    }
////    /// If this WordStatus exists twice on the cloud and delete the older one
////    func deduplicate(cloudNotifactionInfo: CloudKitNotificationInfo) -> CloudKitNotificationInfo {
////        return cloudNotifactionInfo
////    }
////    func extractCloudKitInfo(from notificationPayload: [AnyHashable: Any]) -> CloudKitNotificationInfo? {
////        guard
////            let ckInfo = notificationPayload[AnyHashable("ck")] as? [AnyHashable: Any],
////            let qry = ckInfo["qry"] as? [AnyHashable: Any],
////            let af = qry["af"] as? [String: Any],
////            let cdStatus = af[Cloud.wordStatusKeyStatus] as? Int64,
////            let cdTraditional = af[Cloud.wordStatusKeyTraditional] as? String,
////            let cdLastModified = af[Cloud.wordStatusKeyLastModified] as? Date
////        else {
////            // Return nil if any required field is missing or has the wrong type
////            // This will occur everytime for the default subscription
////            return nil
////        }
////        return CloudKitNotificationInfo(cdTraditional: cdTraditional, cdStatus: cdStatus, cdLastModified: cdLastModified)
////    }
//
//}
