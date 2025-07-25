//
//  UserDefaults.swift
//  ChineseWordOfTheDay
//
//  Created by m on 10/19/24.
//

import Foundation
import CoreDataModels
import Persistence
import CloudKit


struct Constants {
    // MARK: User defaults
    public static let appGroupId = "group.com.matthedm.ChineseWordOfTheDay.AppGroup"
    public static let mockWordKey = "mockWordKey"
    public static let sharedDefaults = UserDefaults(suiteName: Constants.appGroupId)
    // MARK: Core data constants
    public static let STORE_NAME = "WordModel"
    public static let ICLOUD_ID = "iCloud.com.matthedm.ChineseWordOfTheDay"

}

/// Manages user preferences, automatically storing to iCloud when available.
/// Fallsback on `UserDefaults`
struct UserPreferences {
    private static let iCloudStore = NSUbiquitousKeyValueStore.default
    private static let localStore = UserDefaults.standard
}
extension UserPreferences {
    enum Key: String {
        case phoneticNotation
        case chineseWritingSystem
    }
    enum Value: String {
        case zhuyin
        case pinyin
        case traditional
        case simplified
    }

}
extension UserPreferences {
    static func set(_ value: UserPreferences.Value, for key: UserPreferences.Key) async {
        if await isCloudKitAvailable(){
            Self.iCloudStore.set(value.rawValue, forKey: key.rawValue)
        } else {
            Self.localStore.set(value.rawValue, forKey: key.rawValue)
        }
    }
    static func get(_ key: UserPreferences.Key) async -> UserPreferences.Value {
        if await isCloudKitAvailable(){
            return UserPreferences.Value(rawValue: Self.iCloudStore.string(forKey: key.rawValue)!)!
        } else {
            return UserPreferences.Value(rawValue: Self.localStore.string(forKey: key.rawValue)!)!
        }
    }
    /// The app will default to using zhuyin and traditional.
    ///
    /// - Returns: True if settings have never been set.
    /// - Note: Zhuyin and traditional are the best and I will throwdown with anyone who disagrees.
    static func setAppDefaults() async {
        async let _ = Self.set(.zhuyin, for: .phoneticNotation)
        async let _ = Self.set(.traditional, for: .chineseWritingSystem)
    }
    static func areUnset() -> Bool {
        let phoneticKey = UserPreferences.Key.phoneticNotation.rawValue
        guard Self.iCloudStore.object(forKey: phoneticKey) != nil ||
                Self.localStore.object(forKey: phoneticKey) != nil
        else { return true }
        let writtingKey = UserPreferences.Key.chineseWritingSystem.rawValue
        guard Self.iCloudStore.object(forKey: writtingKey) != nil ||
                Self.localStore.object(forKey: writtingKey) != nil
        else { return true }
        return false // keys have already been set
    }

    
}

