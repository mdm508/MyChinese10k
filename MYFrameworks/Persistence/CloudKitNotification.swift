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
import CloudKit
import CoreDataModels

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
