//
//  UserPreferences.swift
//  CoreDataModels
//
//  Created by Matthew McLaughlin on 1/15/26.
//

import Foundation


public struct UserPreferences {
    private static let iCloudStore = NSUbiquitousKeyValueStore.default
    public static let sharedDefaults = UserDefaults(suiteName: Constants.appGroupId)

}
extension UserPreferences {
    public enum Key: String {
        case phoneticNotation
        case chineseWritingSystem
        
        var defaultValue: String {
            switch self {
            case .phoneticNotation:
                return Value.zhuyin.rawValue
            case .chineseWritingSystem:
                return Value.traditional.rawValue
            }
        }
        
        var defaultValueEnum: Value {
            switch self {
            case .phoneticNotation:
                return .zhuyin
            case .chineseWritingSystem:
                return .traditional
            }
        }
    }
    public enum Value: String {
        case zhuyin
        case pinyin
        case traditional
        case simplified
    }

}
extension UserPreferences {
    public static func set(_ value: UserPreferences.Value, for key: UserPreferences.Key) {
        Self.iCloudStore.set(value.rawValue, forKey: key.rawValue)
    }
    // This method should never throw an error.
    public static func get(_ key: UserPreferences.Key) -> UserPreferences.Value {
        setAppDefaults() // ensures the keys always exist
        let value = self.iCloudStore.string(forKey: key.rawValue)!
        return UserPreferences.Value(rawValue: value)!
    }
    /// Sets both local and cloud keys to default `.zhuyin` and `.traditional` if either are unset.
    /// - Note: Should be called at startup to avoid errors.
    static func setAppDefaults() {
        if Self.cloudIsUnset(){
            Self.setCloudDefaults()
        }
    }
    static private func setCloudDefaults(){
        Self.iCloudStore.set(UserPreferences.Value.zhuyin.rawValue, forKey: UserPreferences.Key.phoneticNotation.rawValue)
        Self.iCloudStore.set(UserPreferences.Value.traditional.rawValue, forKey: UserPreferences.Key.chineseWritingSystem.rawValue)
    }
    static private func cloudIsUnset() -> Bool {
        let phoneticKey = UserPreferences.Key.phoneticNotation.rawValue
        // guard to ensure each key does not exist. if one exists
        guard Self.iCloudStore.object(forKey: phoneticKey) != nil
        else { return true }
        let writtingKey = UserPreferences.Key.chineseWritingSystem.rawValue
        guard Self.iCloudStore.object(forKey: writtingKey) != nil
        else { return true }
        return false
    }
    
}

