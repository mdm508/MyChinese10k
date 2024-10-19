//
//  UserDefaults.swift
//  ChineseWordOfTheDay
//
//  Created by m on 10/19/24.
//

import Foundation

struct Constants {
    public static let appGroupId = "group.com.matthedm.ChineseWordOfTheDay.AppGroup"
    struct Defaults {
        public static let sharedDefaults = UserDefaults(suiteName: Constants.appGroupId)
        public static let mockWordKey = "mockWordKey"
    }

}
