//
//  LearnStatus.swift
//  ChineseWordOfTheDay
//
//  Created by m on 12/12/23.
//

import Foundation

/// Represents how well known a Word is.
public enum LearnStatus: Int64 {
    /// Don't assume anything about unseen words. Maybe they know it. Maybe not.
    case unseen = 1
    /// Indicates that you familular but have not yet mastered this word.
    case seen = 2
    /// Indicates you are comfortable with this word.
    case known = 3
}
