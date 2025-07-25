//
//  Misc.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 6/11/25.
//

import Foundation

/// Produces todays date in the following format:
/// 2025年6月11日 星期三
func chineseDate() -> String {
    let date = Date()
    let formatter = DateFormatter()
    formatter.locale = Locale(identifier: "zh_Hant_TW")
    formatter.dateStyle = .full
    return formatter.string(from: date)
}
