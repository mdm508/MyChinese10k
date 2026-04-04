//
//  CardSection.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 4/3/26.
//


import Foundation

struct CardSection: Identifiable {
    let id = UUID()
    let monthTitle: String
    let cards: [CardData]
    
    // This helps the Helper sort the sections chronologically
    var date: Date {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        return df.date(from: monthTitle) ?? Date.distantPast
    }
}