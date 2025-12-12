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
//    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
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
//    class AppDelegate: NSObject, UIApplicationDelegate {
//        var delegate: CurrentWordRefreshDelegate?
//        
//        /// Handles app launch setup, including synchronizing iCloud Key-Value Store, setting default user preferences,
//        /// and registering for CloudKit remote notifications.
//        /// - Note: iCloud sync may take a few seconds to propagate across devices.
//        /// - Returns: `true` to indicate successful launch.
//        func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
////            // Copy database BEFORE Core Data initializes to prevent race conditions
////            PersistenceController.copyDatabaseIfNeeded()
////            
////            // Sync iCloud Key-Value Store
////            NSUbiquitousKeyValueStore.default.synchronize()
////            
////            // Set default user preferences if needed
////            UserPreferences.setAppDefaults()
////            
////            // Register for CloudKit remote notifications
////            application.registerForRemoteNotifications()
////            
////            // Debug: Check notification settings
////            UNUserNotificationCenter.current().getNotificationSettings { settings in
////                print("🔔 Notification authorization status: \(settings.authorizationStatus.rawValue)")
////                print("🔔 Alert setting: \(settings.alertSetting.rawValue)")
////                print("🔔 Badge setting: \(settings.badgeSetting.rawValue)")
////                print("🔔 Sound setting: \(settings.soundSetting.rawValue)")
////            }
////            
////            // Trigger CloudKit sync check on launch
////            Task {
////                // Wait a bit for the app to fully initialize
////                try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
////                await checkCloudKitSync()
////            }
////            
////            return true
//            return true
//        }
//        
//        /// Handles CloudKit remote notifications received while the app is in the background.
//        /// This allows the app to sync changes made on other devices automatically.
//        func application(_ application: UIApplication,
//                         didReceiveRemoteNotification userInfo: [AnyHashable: Any],
//                         fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//            
//            print("🔔 Received remote notification: \(userInfo)")
//            
//            // Convert the remote notification payload into a CloudKit notification
//            if let delegate = self.delegate {
//                // Handle WordStatus notifications
//                if let wordInfo = extractCloudKitInfo(from: userInfo) {
//                    print("🔔 Processing WordStatus notification for: \(wordInfo.cdTraditional)")
//                    updateLocalStatus(with: wordInfo)
//                    delegate.refresh()
//                }
//                
//                // Handle WordIndex notifications
//                if let indexInfo = extractWordIndexInfo(from: userInfo) {
//                    print("🔔 Processing WordIndex notification with current: \(indexInfo)")
//                    updateLocalWordIndex(with: indexInfo)
//                    delegate.refresh()
//                }
//            } else {
//                print("⚠️ No delegate set for CloudKit notifications")
//            }
//            completionHandler(.newData)
//        }
//        
//        /// Called when the app becomes active - useful for checking CloudKit sync
//        func applicationDidBecomeActive(_ application: UIApplication) {
//            print("🔔 App became active - checking CloudKit sync")
//            // Trigger a manual CloudKit sync check if needed
//            Task {
//                await checkCloudKitSync()
//            }
//        }
//        
//        /// Manually check CloudKit sync as a fallback
//        private func checkCloudKitSync() async {
//            let context = PersistenceController.shared.context
//            await context.perform {
//                // Check if we have any CloudKit data
//                let indexCount = try? context.count(for: WordIndex.fetchRequest())
//                let statusCount = try? context.count(for: WordStatus.fetchRequest())
//
//                print("🔔 Manual CloudKit check - Indices: \(indexCount ?? 0), Statuses: \(statusCount ?? 0)")
//
//                // If we have no data, this might be a fresh install
//                if (indexCount ?? 0) == 0 && (statusCount ?? 0) == 0 {
//                    print("🔔 No CloudKit data found - this appears to be a fresh install")
//                }
//            }
//
//            // We have local data, try to fetch remote WordIndex to compare
//            await fetchAndCompareRemoteWordIndex()
//        }
//        
//        /// Fetch remote WordIndex from CloudKit and compare with local
//        private func fetchAndCompareRemoteWordIndex() async {
//            // Check CloudKit account status first
//            let accountStatus = try? await Cloud.ck.accountStatus()
//            guard accountStatus == .available else {
//                print("🔔 CloudKit account not available (status: \(accountStatus?.rawValue ?? -1)) - skipping remote fetch")
//                return
//            }
//
//            let db = Cloud.db
//            let context = PersistenceController.shared.context
//
//            do {
//                // Fetch the remote WordIndex record
//                let recordID = CKRecord.ID(recordName: "5AD43F2F-1C34-4B76-87B4-E818F948D54D", zoneID: Cloud.wordStatusRecordZone.zoneID)
//                let remoteRecord = try await db.record(for: recordID)
//
//                if let remoteCurrent = remoteRecord["CD_current"] as? Int64 {
//                    print("🔔 Remote WordIndex current: \(remoteCurrent)")
//
//                    // Compare with local
//                    await context.perform {
//                        if let localIndex = try? context.fetch(WordIndex.fetchRequest()).first {
//                            print("🔔 Local WordIndex current: \(localIndex.current)")
//
//                            if remoteCurrent > localIndex.current {
//                                print("🔔 Remote index (\(remoteCurrent)) > local (\(localIndex.current)) - updating")
//                                localIndex.current = remoteCurrent
//                                try? context.save()
//
//                                // Trigger UI refresh
//                                if let delegate = self.delegate {
//                                    delegate.refresh()
//                                }
//                            } else {
//                                print("🔔 Remote index (\(remoteCurrent)) <= local (\(localIndex.current)) - no update needed")
//                            }
//                        }
//                    }
//                }
//            } catch {
//                print("🔔 Failed to fetch remote WordIndex: \(error)")
//            }
//        }
//        
//        /// Updates the local Core Data status based on CloudKit notification information.
//        /// - Parameter wordInfo: The CloudKit notification information containing word status updates.
//        private func updateLocalStatus(with wordInfo: CloudKitNotificationInfo) {
//            let context = PersistenceController.shared.context
//            context.perform {
//                // Find or create WordStatus with the matching traditional character
//                let fetchRequest: NSFetchRequest<WordStatus> = WordStatus.fetchRequest()
//                fetchRequest.predicate = NSPredicate(format: "traditional == %@", wordInfo.cdTraditional)
//                fetchRequest.fetchLimit = 1
//
//                do {
//                    if let wordStatus = try context.fetch(fetchRequest).first {
//                        // Update existing WordStatus
//                        wordStatus.status = wordInfo.cdStatus
//                        wordStatus.lastModified = wordInfo.cdLastModified
//                        print("🔄 Updated existing WordStatus for '\(wordInfo.cdTraditional)' to status \(wordInfo.cdStatus)")
//                    } else {
//                        // Create new WordStatus
//                        let newWordStatus = WordStatus(context: context)
//                        newWordStatus.traditional = wordInfo.cdTraditional
//                        newWordStatus.status = wordInfo.cdStatus
//                        newWordStatus.lastModified = wordInfo.cdLastModified
//                        print("🔄 Created new WordStatus for '\(wordInfo.cdTraditional)' with status \(wordInfo.cdStatus)")
//                    }
//
//                    try context.save()
//                } catch {
//                    print("❌ Failed to update local WordStatus: \(error)")
//                }
//            }
//        }
//        
//        /// Extracts WordIndex information from CloudKit notification payload.
//        /// - Parameter notificationPayload: The notification payload from CloudKit.
//        /// - Returns: The current index value if extraction is successful; otherwise, `nil`.
//        private func extractWordIndexInfo(from notificationPayload: [AnyHashable: Any]) -> Int64? {
//            // Extract the CloudKit-specific payload
//            guard let ckInfo = notificationPayload[AnyHashable("ck")] as? [AnyHashable: Any] else {
//                return nil
//            }
//
//            // Extract the query dictionary
//            guard let qry = ckInfo["qry"] as? [String: Any] else {
//                return nil
//            }
//
//            // Extract additional fields ('af') from the query
//            guard let af = qry["af"] as? [String: Any] else {
//                return nil
//            }
//
//            // Retrieve the current index value
//            guard let currentIndex = af[Cloud.wordIndexKeyCurrent] as? Int64 else {
//                return nil
//            }
//
//            return currentIndex
//        }
//        
//        /// Updates the local WordIndex based on CloudKit notification information.
//        /// - Parameter currentIndex: The current index value from CloudKit.
//        private func updateLocalWordIndex(with currentIndex: Int64) {
//            let context = PersistenceController.shared.context
//            context.perform {
//                do {
//                    // Find existing WordIndex or create new one
//                    let fetchRequest: NSFetchRequest<WordIndex> = WordIndex.fetchRequest()
//                    fetchRequest.fetchLimit = 1
//
//                    let wordIndex: WordIndex
//                    if let existing = try context.fetch(fetchRequest).first {
//                        wordIndex = existing
//
//                        // Only update if remote index is higher than local index
//                        if currentIndex > wordIndex.current {
//                            wordIndex.current = currentIndex
//                            try context.save()
//                            print("🔄 Updated WordIndex current from \(wordIndex.current - 1) to \(currentIndex)")
//                        } else {
//                            print("🔄 Ignored WordIndex update: remote (\(currentIndex)) <= local (\(wordIndex.current))")
//                        }
//                    } else {
//                        // Create new WordIndex for first-time users
//                        wordIndex = WordIndex(context: context)
//                        wordIndex.current = currentIndex
//                        try context.save()
//                        print("🔄 Created new WordIndex with current: \(currentIndex)")
//                    }
//                } catch {
//                    print("❌ Failed to update WordIndex: \(error)")
//                }
//            }
//        }
//    }
}
