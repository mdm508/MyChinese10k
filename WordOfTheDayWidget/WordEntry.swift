//
//  WordEntry.swift
//  ChineseWordOfTheDay
//
//  Created by m on 3/15/26.
//

import WidgetKit
import CoreDataModels

struct WordEntry: TimelineEntry {
    let date: Date
    let word: WordRepresentable
    let selectedMeaning: String?
}
