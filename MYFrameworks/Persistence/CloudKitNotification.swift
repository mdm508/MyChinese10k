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
import CoreDataModels

/// Lightweight struct to store information from remote notifactions in
public struct CloudKitNotificationInfo {
    let cdTraditional: String
    let cdStatus: Int64
    let cdLastModified: Date
    public init(cdTraditional: String, cdStatus: Int64, cdLastModified: Date) {
        self.cdTraditional = cdTraditional
        self.cdStatus = cdStatus
        self.cdLastModified = cdLastModified
    }
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
    public static let subID = "wordStatusSubscription"
    public static let wordStatusRecordZone = CKRecordZone(zoneName: "com.apple.coredata.cloudkit.zone")
}
extension Cloud {
    public static let wordStatusRecordType = "CD_WordStatus"
    public static let wordStatusKeyTraditional = "CD_traditional"
    public static let wordStatusKeyStatus = "CD_status"
    public static let wordStatusKeyLastModified = "CD_lastModified"
    
    public static let wordStatusAllKeys = [Self.wordStatusKeyTraditional, Self.wordStatusKeyStatus, Self.wordStatusKeyLastModified]
}
@MainActor
public func createCloudKitRecord(for word: Word, completion: @escaping () -> ()) {
    let hexString = convertChineseToHex(chineseCharacter: word.traditional)
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
            Task { @MainActor in
                        completion()
                    }
        }
    }
}

/// when you receive a custom notification (not default) transform it into `CloudKitNotification`
/// - Parameter notificationPayload: notification from remote.
/// - Returns: nil or a `CloudKitNotification`
public func extractCloudKitInfo(from notificationPayload: [AnyHashable: Any]) -> CloudKitNotificationInfo? {
    guard let ckInfo = notificationPayload[AnyHashable("ck")] as? [AnyHashable: Any] else {
        print("Failed to extract 'ck' from notificationPayload.")
        return nil
    }
    guard let qry = ckInfo["qry"] as? [String: Any] else {
        // "qry" is not present in ckInfo.
        // this must be a default notification so ignore it.
        return nil
    }
    guard let af = qry["af"] as? [String: Any] else {
        print("Failed to extract 'af' from qry.")
        return nil
    }
    guard let cdTraditional = af[Cloud.wordStatusKeyTraditional] as? String else {
            print("Failed to extract '\(Cloud.wordStatusKeyTraditional)' from af.")
            return nil
    }
    guard let cdStatus = af[Cloud.wordStatusKeyStatus] as? Int64 else {
        print("Failed to extract '\(Cloud.wordStatusKeyStatus)' from af.")
        return nil
    }
    var cdLastModified: Date! = nil
    if let timestampNumber = af[Cloud.wordStatusKeyLastModified] as? NSNumber {
        // If the value is a number, convert it using timeIntervalSince1970.
        cdLastModified = Date(timeIntervalSince1970: timestampNumber.doubleValue)
    } else if let timestampString = af[Cloud.wordStatusKeyLastModified] as? String,
              let timestampDouble = Double(timestampString) {
        // If the value is a string, try converting it to a Double first.
        cdLastModified = Date(timeIntervalSince1970: timestampDouble)
    }
    guard cdLastModified != nil else {
        print("Failed to extract or convert '\(Cloud.wordStatusKeyLastModified)' from af.")
        return nil
    }
    return CloudKitNotificationInfo(cdTraditional: cdTraditional, cdStatus: cdStatus, cdLastModified: cdLastModified)
}


/// Save CKWordStatus to cloud.
public func createCloudKitRecord(for word: Word) async throws {
    let hexString = convertChineseToHex(chineseCharacter: word.traditional)
    let ckID = CKRecord.ID(recordName: hexString, zoneID: Cloud.wordStatusRecordZone.zoneID)

    let newRecord = CKRecord(recordType: Cloud.wordStatusRecordType, recordID: ckID)
    newRecord["CD_entityName"] = "WordStatus"
    newRecord[Cloud.wordStatusKeyTraditional] = word.traditional as CKRecordValue
    newRecord[Cloud.wordStatusKeyStatus] = LearnStatus.seen.rawValue as CKRecordValue
    newRecord[Cloud.wordStatusKeyLastModified] = Date() as CKRecordValue
    let db = Cloud.db
    let savedRecord = try await db.save(newRecord)
    print("Successfully saved record with ID: \(savedRecord.recordID.recordName)")
}


/// If a cloud kit subscription does not exist then set one up
public func setupCloudSub() {
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
            print("sub already exists")
        }
    }
}

public func convertChineseToHex(chineseCharacter: String) -> String {
    let utf8Data = chineseCharacter.data(using: .utf8)!
    return utf8Data.map { String(format: "%02x", $0) }.joined()
}

///// Updates matching local entity with the new status
//@MainActor
//public func updateLocalStatus(with new: CloudKitNotificationInfo){
//    let request = Word.fetchRequest()
//    request.predicate = NSPredicate(format: "traditional == %@", argumentArray: [new.cdTraditional])
//    print(new)
//    request.fetchLimit = 1
//    let managedObjectContext = PersistenceController.shared.context
//    do {
//        // Fetch the words matching the predicate
//        if let localWord = try managedObjectContext.fetch(request).first {
//            print(localWord.debugDescription)
//            localWord.status = new.cdStatus
//            print("updated \(localWord.traditional)")
//            print(localWord.status)
//        } else {
//            print("unable to update \(new)")
//        }
//        // Save the changes to the managed object context
//        try managedObjectContext.save()
//    } catch {
//        print("Error fetching or updating words: \(error.localizedDescription)")
//    }
//}



/// updates all the local records with the statuses found in the cloud
//@MainActor
//public func updateAllLocalStatus() async {
//    let db = Cloud.db
//    let query = CKQuery(recordType: Cloud.wordStatusRecordType, predicate: NSPredicate(value: true))
//    // Create a query object. Assuming 'WordStatus' is your record type.
//    // Perform the query
//    do {
//        let records = try await db.records(matching: query, inZoneWith: Cloud.wordStatusRecordZone.zoneID, desiredKeys: Cloud.wordStatusAllKeys)
//        let matchResults: [(CKRecord.ID, Result<CKRecord, Error>)] = records.matchResults
//        print("will update \(matchResults.count) records from icloud")
//        for (id, result) in matchResults {
//            switch (result){
//            case .success(let record):
//                let word = record[Cloud.wordStatusKeyTraditional]! as! String
//                let status = record[Cloud.wordStatusKeyStatus]! as! Int64
//                let modified = record[Cloud.wordStatusKeyLastModified]! as! Date
//                updateLocalStatus(with: CloudKitNotificationInfo(cdTraditional: word, cdStatus: status, cdLastModified: modified))
//            case .failure(let error):
//                print("Record \(id) unable unable to be fetched.")
//                print(error.localizedDescription)
//            }
//        }
//        
//    } catch {
//        print(error.localizedDescription)
//    }
//
//}

//public func updateAllLocalStatus() async {
//    let db = Cloud.db
//    let query = CKQuery(recordType: Cloud.wordStatusRecordType, predicate: NSPredicate(value: true))
//
//    do {
//        let records = try await db.records(matching: query, inZoneWith: Cloud.wordStatusRecordZone.zoneID, desiredKeys: Cloud.wordStatusAllKeys)
//        let matchResults: [(CKRecord.ID, Result<CKRecord, Error>)] = records.matchResults
//
//        print("Fetched \(matchResults.count) records from iCloud")
//
//        for (id, result) in matchResults {
//            switch result {
//            case .success(let record):
//                guard let word = record[Cloud.wordStatusKeyTraditional] as? String,
//                      let status = record[Cloud.wordStatusKeyStatus] as? Int64,
//                      let modified = record[Cloud.wordStatusKeyLastModified] as? Date else {
//                    print("Error: Missing required fields in CloudKit record \(record.recordID)")
//                    continue
//                }
//
//                // Ensure local updates happen on the main thread
//                DispatchQueue.main.async {
//                    updateLocalStatus(with: CloudKitNotificationInfo(cdTraditional: word, cdStatus: status, cdLastModified: modified))
//                }
//
//            case .failure(let error):
//                print("Record \(id) unable to be fetched: \(error.localizedDescription)")
//            }
//        }
//    } catch {
//        print("Error fetching records: \(error.localizedDescription)")
//    }
//}


