//
//  CloudKitNotification.swift
//  ChineseWordOfTheDay
//
//  Created by m on 12/5/23.
//
// This file handles functionality related to receiving remote notifications from CloudKit,
// updating local data based on those notifications, and setting up CloudKit subscriptions.
//

import Foundation
import UIKit
import CloudKit
import CoreDataModels

// MARK: - CloudKit Notification Structures & Protocols

/// A lightweight structure to encapsulate information extracted from CloudKit remote notifications.
public struct CloudKitNotificationInfo {
    /// The traditional Chinese string from the notification.
    public let cdTraditional: String
    /// The status value associated with the word.
    public let cdStatus: Int64
    /// The date when the record was last modified.
    public let cdLastModified: Date
    
    /// Initializes a new instance of `CloudKitNotificationInfo`.
    /// - Parameters:
    ///   - cdTraditional: The traditional Chinese character.
    ///   - cdStatus: The status number.
    ///   - cdLastModified: The last modified date.
    public init(cdTraditional: String, cdStatus: Int64, cdLastModified: Date) {
        self.cdTraditional = cdTraditional
        self.cdStatus = cdStatus
        self.cdLastModified = cdLastModified
    }
}

/// Delegate protocol used to refresh the current word when a successful local status update
/// is triggered by a CloudKit notification.
public protocol CurrentWordRefreshDelegate: AnyObject {
    func refresh()
}

// MARK: - CloudKit Configuration Constants

/// A collection of related CloudKit constants.
public struct Cloud {
    /// Setup the CloudKit container with a specific identifier.
    /// - Note: `CKContainer.default` may have a different identifier.
    public static let ck = CKContainer(identifier: "iCloud.com.matthedm.ChineseWordOfTheDay")
    /// Access to the private CloudKit database.
    public static var db: CKDatabase {
        return ck.privateCloudDatabase
    }
    /// Subscription identifier for CloudKit notifications.
    public static let subID = "wordStatusSubscription"
    /// The default record zone for word status notifications.
    public static let wordStatusRecordZone = CKRecordZone(zoneName: "com.apple.coredata.cloudkit.zone")
    /// User default key for CKAccountStatus
    public static let ckAccountStatusKey = "ckAccountStatus"
}

extension Cloud {
    /// The record type used for word statuses.
    public static let wordStatusRecordType = "CD_WordStatus"
    /// The key used for storing the traditional string.
    public static let wordStatusKeyTraditional = "CD_traditional"
    /// The key used for storing the status value.
    public static let wordStatusKeyStatus = "CD_status"
    /// The key used for storing the last modified date.
    public static let wordStatusKeyLastModified = "CD_lastModified"
    /// An array of all keys that are important for the CloudKit record.
    public static let wordStatusAllKeys = [wordStatusKeyTraditional, wordStatusKeyStatus, wordStatusKeyLastModified]
    
    /// The record type used for word index.
    public static let wordIndexRecordType = "CD_WordIndex"
    /// The key used for storing the current index.
    public static let wordIndexKeyCurrent = "CD_current"
    /// An array of all keys that are important for the WordIndex CloudKit record.
    public static let wordIndexAllKeys = [wordIndexKeyCurrent]
}

// MARK: - CloudKit Record Creation

/// Creates a CloudKit record for a given `Word` object. Invokes the completion handler upon success.
/// - Parameters:
///   - word: The `Word` object to create the record for.
///   - completion: Completion closure executed on success.
@MainActor
public func createCloudKitRecord(for word: Word, completion: @escaping () -> Void) {
    let record = makeCloudKitRecord(for: word)
    // Save the record to the CloudKit database.
    Cloud.db.save(record) { savedRecord, error in
        if let error = error {
            print("Error saving record: \(error.localizedDescription)")
        } else {
            print("Successfully saved record with ID: \(savedRecord?.recordID.recordName ?? "")")
            // Ensure completion is executed on the main thread.
            Task { @MainActor in
                completion()
            }
        }
    }
}

/// Asynchronously creates a CloudKit record for a given `Word` object using async/await.
/// - Parameter word: The `Word` object to create the record for.
/// - Throws: An error if the save operation fails.
public func createCloudKitRecord(for word: Word) async throws {
    let record = makeCloudKitRecord(for: word)
    let savedRecord = try await Cloud.db.save(record)
    print("Successfully saved record with ID: \(savedRecord.recordID.recordName)")
}

/// Constructs and configures a `CKRecord` for a given `Word` object.
/// This function encapsulates the shared record configuration logic.
/// - Parameter word: The `Word` object used to configure the record.
/// - Returns: A fully configured `CKRecord`.
private func makeCloudKitRecord(for word: Word) -> CKRecord {
    let hexString = convertChineseToHex(chineseCharacter: word.traditional)
    let ckID = CKRecord.ID(recordName: hexString, zoneID: Cloud.wordStatusRecordZone.zoneID)
    let record = CKRecord(recordType: Cloud.wordStatusRecordType, recordID: ckID)
    
    // Set the entity name (consider moving this to a constant)
    record["CD_entityName"] = "WordStatus"
    // Set record values using the provided `Word` object's properties.
    record[Cloud.wordStatusKeyTraditional] = word.traditional as CKRecordValue
    record[Cloud.wordStatusKeyStatus] = LearnStatus.seen.rawValue as CKRecordValue
    record[Cloud.wordStatusKeyLastModified] = Date() as CKRecordValue
    
    return record
}

// MARK: - CloudKit Notification Handling

/// Extracts and transforms remote notification payload data into a `CloudKitNotificationInfo` object.
/// - Parameter notificationPayload: The remote notification payload dictionary.
/// - Returns: A `CloudKitNotificationInfo` object if extraction is successful; otherwise, `nil`.
public func extractCloudKitInfo(from notificationPayload: [AnyHashable: Any]) -> CloudKitNotificationInfo? {
    // Extract the CloudKit-specific payload.
    guard let ckInfo = notificationPayload[AnyHashable("ck")] as? [AnyHashable: Any] else {
        print("Failed to extract 'ck' from notificationPayload.")
        return nil
    }
    // Extract the query dictionary. If absent, this is a default notification, so ignore it.
    guard let qry = ckInfo["qry"] as? [String: Any] else {
        return nil
    }
    // Extract additional fields ('af') from the query.
    guard let af = qry["af"] as? [String: Any] else {
        print("Failed to extract 'af' from qry.")
        return nil
    }
    
    // Retrieve the traditional Chinese string.
    guard let cdTraditional = af[Cloud.wordStatusKeyTraditional] as? String else {
        print("Failed to extract '\(Cloud.wordStatusKeyTraditional)' from af.")
        return nil
    }
    // Retrieve the status value.
    guard let cdStatus = af[Cloud.wordStatusKeyStatus] as? Int64 else {
        print("Failed to extract '\(Cloud.wordStatusKeyStatus)' from af.")
        return nil
    }
    
    // Convert the last modified timestamp from a number or string to a Date.
    var cdLastModified: Date? = nil
    if let timestampNumber = af[Cloud.wordStatusKeyLastModified] as? NSNumber {
        cdLastModified = Date(timeIntervalSince1970: timestampNumber.doubleValue)
    } else if let timestampString = af[Cloud.wordStatusKeyLastModified] as? String,
              let timestampDouble = Double(timestampString) {
        cdLastModified = Date(timeIntervalSince1970: timestampDouble)
    }
    
    guard let lastModified = cdLastModified else {
        print("Failed to extract or convert '\(Cloud.wordStatusKeyLastModified)' from af.")
        return nil
    }
    return CloudKitNotificationInfo(cdTraditional: cdTraditional, cdStatus: cdStatus, cdLastModified: lastModified)
}

// MARK: - CloudKit Subscription Setup

/// Sets up CloudKit subscriptions for both WordStatus and WordIndex updates.
/// - Note: The notification payloads are configured to include all necessary keys.
public func setupCloudSub() {
    print("🔔 Setting up CloudKit subscriptions...")
    let db = Cloud.db
    
    // Setup WordStatus subscription
    setupWordStatusSubscription(db: db)
    
    // Setup WordIndex subscription
    setupWordIndexSubscription(db: db)
    
    print("🔔 CloudKit subscription setup completed")
}

private func setupWordStatusSubscription(db: CKDatabase) {
    let subID = Cloud.subID
    db.fetch(withSubscriptionID: subID) { subscription, error in
        if let error = error {
            print("Error fetching WordStatus subscription: \(error.localizedDescription)")
        }
        if subscription == nil {
            let sub = CKQuerySubscription(
                recordType: Cloud.wordStatusRecordType,
                predicate: NSPredicate(value: true),
                subscriptionID: subID,
                options: [.firesOnRecordCreation, .firesOnRecordUpdate]
            )
            let notification = CKSubscription.NotificationInfo()
            notification.shouldSendContentAvailable = true
            notification.desiredKeys = Cloud.wordStatusAllKeys
            sub.notificationInfo = notification
            db.save(sub) { savedSubscription, error in
                if let error = error {
                    print("Error saving WordStatus subscription: \(error.localizedDescription)")
                } else {
                    print("Successfully created WordStatus subscription with ID: \(savedSubscription?.subscriptionID ?? "")")
                }
            }
        } else {
            print("WordStatus subscription already exists.")
        }
    }
}

private func setupWordIndexSubscription(db: CKDatabase) {
    let subID = "wordIndexSubscription"
    db.fetch(withSubscriptionID: subID) { subscription, error in
        if let error = error {
            print("Error fetching WordIndex subscription: \(error.localizedDescription)")
        }
        if subscription == nil {
            let sub = CKQuerySubscription(
                recordType: Cloud.wordIndexRecordType,
                predicate: NSPredicate(value: true),
                subscriptionID: subID,
                options: [.firesOnRecordCreation, .firesOnRecordUpdate]
            )
            let notification = CKSubscription.NotificationInfo()
            notification.shouldSendContentAvailable = true
            notification.desiredKeys = Cloud.wordIndexAllKeys
            sub.notificationInfo = notification
            db.save(sub) { savedSubscription, error in
                if let error = error {
                    print("Error saving WordIndex subscription: \(error.localizedDescription)")
                } else {
                    print("Successfully created WordIndex subscription with ID: \(savedSubscription?.subscriptionID ?? "")")
                }
            }
        } else {
            print("WordIndex subscription already exists.")
        }
    }
}

// MARK: - Utility Functions

/// Converts a Chinese string to a hexadecimal representation.
/// - Parameter chineseCharacter: A string containing Chinese characters.
/// - Returns: A hexadecimal string corresponding to the UTF-8 encoded data.
public func convertChineseToHex(chineseCharacter: String) -> String {
    guard let utf8Data = chineseCharacter.data(using: .utf8) else {
        return ""
    }
    return utf8Data.map { String(format: "%02x", $0) }.joined()
}

///// Update user defaults with users cloud kit status
//public func saveCKAccountStatusToUserDefaults() async {
//    await status = Cloud.ck.acccountStatus()
//    UserDefaults.standard.set(?,forKey: Cloud.ckAccountStatusKey)
//}

/// Convenience method to determine if the user is connected to iCloud.
///
/// - Returns: The user's `CKAccountStatus`.
/// - Note: If an error occurs during the check, `.couldNotDetermine` is returned.
public func getCloudAccountStatus() async -> CKAccountStatus {
    do {
        let status = try await Cloud.ck.accountStatus()
        return status
    } catch {
        return .couldNotDetermine
    }
}

///
public func isCloudKitAvailable() async -> Bool {
    let accountStatus: CKAccountStatus = await getCloudAccountStatus()
    return accountStatus == .available
}
