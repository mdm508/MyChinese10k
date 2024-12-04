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


/// Lightweight struct to store information from remote notifactions in
struct CloudKitNotificationInfo {
    let cdTraditional: String
    let cdStatus: Int64
    let cdLastModified: Date
}

/// This delegate's refresh method is invoked upon successful local status update triggered by an iCloud notification.
public protocol CurrentWordRefreshDelegate: AnyObject {
    func refresh() -> ()
}

/// A collection of related CloudKit contsants
public struct Cloud{
    /// Must setup container like this because `CKContainer.default` has a different identifier
    public static let ck = CKContainer(identifier: "iCloud.com.matthedm.ChineseWordOfTheDay")
    public static var db: CKDatabase {
        ck.privateCloudDatabase
    }
    /// Default subrciption that is setup for you by the CloudKit Container
    static let subID = "wordStatusSubscription"
    public static let wordStatusRecordZone = CKRecordZone(zoneName: "com.apple.coredata.cloudkit.zone")
}
extension Cloud {
    public static let wordStatusRecordType = "CD_WordStatus"
    public static let wordStatusKeyTraditional = "CD_traditional"
    public static let wordStatusKeyStatus = "CD_status"
    public static let wordStatusKeyLastModified = "CD_lastModified"
    
    public static let wordStatusAllKeys = [Self.wordStatusKeyTraditional, Self.wordStatusKeyStatus, Self.wordStatusKeyLastModified]
}
public func createCloudKitRecord(for word: Word, completion: () -> ()) {
    let hexString = convertChineseToHex(chineseCharacter: word.traditional)
//    let ckID = CKRecord.ID(recordName: hexString)
    let ckID = CKRecord.ID(recordName: hexString, zoneID: Cloud.wordStatusRecordZone.zoneID)

    let newRecord = CKRecord(recordType: Cloud.wordStatusRecordType, recordID: ckID)
    newRecord["CD_entityName"] = "WordStatus" //TODO: make into a constant
    // Set the appropriate fields for the new record based on your WordStatus entity
    newRecord[Cloud.wordStatusKeyTraditional] = word.traditional as CKRecordValue
    newRecord[Cloud.wordStatusKeyStatus] = LearnStatus.seen.rawValue as CKRecordValue
    newRecord[Cloud.wordStatusKeyLastModified] = Date() as CKRecordValue
    // Save the record to the public CloudKit database
    let db = Cloud.db
    db.save( newRecord) { savedRecord, error in
        if let error = error {
            print("Error saving record: \(error.localizedDescription)")
        } else {
            print("Successfully saved record with ID: \(savedRecord?.recordID.recordName ?? "")")
        }
    }
}



/// If a cloud kit subscription does not exist then set one up
func setupCloudSub() {
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
        }
    }
}

func convertChineseToHex(chineseCharacter: String) -> String {
    let utf8Data = chineseCharacter.data(using: .utf8)!
    return utf8Data.map { String(format: "%02x", $0) }.joined()
}

/// Updates matching local entity with the new status
@MainActor
func updateLocalStatus(with new: CloudKitNotificationInfo){
    let request = Word.fetchRequest()
    request.predicate = NSPredicate(format: "traditional == %@", argumentArray: [new.cdTraditional])
    request.fetchLimit = 1
    let managedObjectContext = PersistenceController.shared.context
    do {
        // Fetch the words matching the predicate
        if let localWord = try managedObjectContext.fetch(request).first {
            print(localWord.status)
            print(localWord.traditional)
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
@MainActor
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
                let modified = record[Cloud.wordStatusKeyLastModified]! as! Date
                updateLocalStatus(with: CloudKitNotificationInfo(cdTraditional: word, cdStatus: status, cdLastModified: modified))
            case .failure(let error):
                print("Record \(id) unable unable to be fetched.")
                print(error.localizedDescription)
            }
        }
        
    } catch {
        print(error.localizedDescription)
    }

}

