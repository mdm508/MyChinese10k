//
//  PersistenceHelperModels.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 3/27/26.
//

import Combine

public enum StorageActor: String, CaseIterable {
    case swiftuiApp, widget
}
extension Notification.Name {
    public static let cdcksStoreDidChange = Notification.Name("cdcksStoreDidChange")
}
extension NotificationCenter {
    public var storeDidChangePublisher: Publishers.ReceiveOn<NotificationCenter.Publisher, DispatchQueue> {
        return publisher(for: .cdcksStoreDidChange).receive(on: DispatchQueue.main)
    }
}
struct UserInfoKey {
    static let storeUUID = "storeUUID"
    static let transactions = "transactions"
}
