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


struct CloudKitNotificationInfo {
    let cdTraditional: String
    let cdStatus: Int64
}

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

/// A collection of related CloudKit contsants
struct Cloud{
    static let ck = CKContainer(identifier: "iCloud.com.matthedm.ChineseWordOfTheDay")
    static var db: CKDatabase {
        ck.privateCloudDatabase
    }
    static let subID = "wordStatus"
    static let wordStatusRecordZone = CKRecordZone(zoneName: "com.apple.coredata.cloudkit.zone")
}
extension Cloud {
    static let wordStatusRecordType = "CD_WordStatus"
    static let wordStatusKeyTraditional = "CD_traditional"
    static let wordStatusKeyStatus = "CD_status"
    static let wordStatusAllKeys = [Self.wordStatusKeyTraditional, Self.wordStatusKeyStatus]
}
/// If a cloud kit subscription does not exist then set one up
func setupCloudSub() {
    /// Must setup container like this because `CKContainer.default` has a different identifier
    let db = Cloud.db
    db.fetch(withSubscriptionID: Cloud.subID){ sub, error in
        if let error = error  {
            print(error.localizedDescription)
        }
        if sub == nil {
            let sub = CKQuerySubscription(recordType: Cloud.wordStatusRecordType,
                                predicate: NSPredicate(value: true),
                                          subscriptionID: Cloud.subID,
                                          options: .firesOnRecordCreation)
            let notification = CKSubscription.NotificationInfo()
            notification.shouldSendContentAvailable = true
            ///ensure fields included in the payload
            notification.desiredKeys = Cloud.wordStatusAllKeys
            sub.notificationInfo = notification
            db.save(sub) { (subscription, error) in
                 if let error = error {
                     print(error.localizedDescription)
                 }
            }
        } else {
            print("sub is all good")
        }
    }
}

func extractCloudKitInfo(from notificationPayload: [AnyHashable: Any]) -> CloudKitNotificationInfo? {
    guard
        let ckInfo = notificationPayload[AnyHashable("ck")] as? [AnyHashable: Any],
        let qry = ckInfo["qry"] as? [AnyHashable: Any],
        let af = qry["af"] as? [String: Any],
        let cdStatus = af[Cloud.wordStatusKeyStatus] as? Int64,
        let cdTraditional = af[Cloud.wordStatusKeyTraditional] as? String
    else {
        // Return nil if any required field is missing or has the wrong type
        return nil
    }
    return CloudKitNotificationInfo(cdTraditional: cdTraditional, cdStatus: cdStatus)
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


/// updates all the local records with the statuses found in the cloud
func updateAllLocalStatus() async {
    let db = Cloud.db
    let query = CKQuery(recordType: Cloud.wordStatusRecordType, predicate: NSPredicate(value: true))
    // Create a query object. Assuming 'WordStatus' is your record type.
    // Perform the query
    do {
        let records = try await db.records(matching: query, inZoneWith: Cloud.wordStatusRecordZone.zoneID, desiredKeys: Cloud.wordStatusAllKeys)
        let matchResults: [(CKRecord.ID, Result<CKRecord, Error>)] = records.matchResults
        print("will update \(matchResults.count) records from icloud")
        for (id, result) in matchResults {
            switch (result){
            case .success(let record):
                let word = record[Cloud.wordStatusKeyTraditional]! as! String
                let status = record[Cloud.wordStatusKeyStatus]! as! Int64
                updateLocalStatus(with: CloudKitNotificationInfo(cdTraditional: word, cdStatus: status))
            case .failure(let error):
                print("Record \(id) unable unable to be fetched.")
                print(error.localizedDescription)
            }
        }
        
    } catch {
        print(error.localizedDescription)
    }

}

