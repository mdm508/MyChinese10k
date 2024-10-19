//
//  LearnStatus.swift
//  ChineseWordOfTheDay
//
//  Created by m on 12/12/23.
//

import Foundation

/// Represents how well known a Word is.
enum LearnStatus: Int64 {
    case unseen = 1 /// Maybe you know it but it hasn't appeared as todays word yet.
    case seen = 2 /// Indicates that you have seen the word or are familular with it but not yet mastered
    case known = 3 /// Indicates you are comfortable with the word
}
