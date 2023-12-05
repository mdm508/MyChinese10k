//
//  CloudKitNotification.swift
//  ChineseWordOfTheDay
//
//  Created by m on 12/5/23.
//
// Functionality related to receiving remote notifications from CloudKit

import Foundation
import UIKit
import CloudKit

/// This delegate's refresh method is invoked upon successful local status update triggered by an iCloud notification.
protocol CurrentWordRefreshDelegate {
    func refresh() -> ()
}

typealias CloudKitNotificationInfo = (cdTraditional: String, cdStatus: Int64)

class AppDelegate: NSObject, UIApplicationDelegate {
    let gcmMessageIDKey = "gcm.message_id"
    var delegate: CurrentWordRefreshDelegate?
    
}

extension AppDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        application.registerForRemoteNotifications()
        return true
    }
    /// Method to receive remote notifications from a cloudKit publisher
    /// - SeeAlso: [UIapplicationDelegate documentation](https://developer.apple.com/documentation/uikit/uiapplicationdelegate/1623013-application)
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        if let info = extractCloudKitInfo(from: userInfo){
            updateLocalStatus(with: info)
            self.delegate?.refresh()
            completionHandler(.newData)
            return
        }
        completionHandler(.failed)
    }
}

/// If a cloud kit subscription does not exist then set one up
func setupCloudSub() {
    /// Must setup container like this because `CKContainer.default` has a different identifier
    let ck = CKContainer(identifier: "iCloud.com.matthedm.ChineseWordOfTheDay")
    let db = ck.privateCloudDatabase
    db.fetch(withSubscriptionID: "wordStatus"){ sub, error in
        if let error = error  {
            print(error.localizedDescription)
        }
        if sub == nil {
            let sub = CKQuerySubscription(recordType: "CD_WordStatus",
                                predicate: NSPredicate(value: true),
                                subscriptionID: "wordStatus",
                                          options: .firesOnRecordCreation)
            let notification = CKSubscription.NotificationInfo()
            notification.shouldSendContentAvailable = true
            ///ensure fields included in the payload
            notification.desiredKeys = ["CD_traditional", "CD_status",]
            sub.notificationInfo = notification
            db.save(sub) { (subscription, error) in
                 if let error = error {
                     print(error.localizedDescription)
                 }
            }
        }
    }
}

func extractCloudKitInfo(from notificationPayload: [AnyHashable: Any]) -> CloudKitNotificationInfo? {
    guard
        let ckInfo = notificationPayload[AnyHashable("ck")] as? [AnyHashable: Any],
        let qry = ckInfo["qry"] as? [AnyHashable: Any],
        let af = qry["af"] as? [String: Any],
        let cdStatus = af["CD_status"] as? Int64,
        let cdTraditional = af["CD_traditional"] as? String
    else {
        // Return nil if any required field is missing or has the wrong type
        return nil
    }
    return (cdTraditional: cdTraditional, cdStatus: cdStatus)
}

/// Updates matching local entity with the new status
func updateLocalStatus(with new: CloudKitNotificationInfo){
    let request = Word.fetchRequest()
    request.predicate = NSPredicate(format: "traditional == %@", argumentArray: [new.cdTraditional])
    request.fetchLimit = 1
    let managedObjectContext = PersistenceController.shared.context
    do {
        // Fetch the words matching the predicate
        if let localWord = try managedObjectContext.fetch(request).first {
            localWord.status = new.cdStatus
        } else {
            print("unable to update \(new)")
        }
        // Save the changes to the managed object context
        try managedObjectContext.save()
    } catch {
        print("Error fetching or updating words: \(error.localizedDescription)")
    }
}
