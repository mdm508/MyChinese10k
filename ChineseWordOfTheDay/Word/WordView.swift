//
//  WordView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 6/16/23.
// 'id like to fit tha characters into that space'

import SwiftUI
import CoreDataModels

struct WordView {
    var word: String
    var size:  CGSize
}
extension WordView: View {
    var body: some View {
        Text(self.word)
            .font(.system(size: fontSize()))
            .multilineTextAlignment(.center)
            .allowsTightening(true)
            .textSelection(.enabled)
    }
}
extension WordView {
    func fontSize() -> CGFloat {
        let base = min(size.width, size.height) * 0.95
        switch word.count {
        case 1:
            return base
        case 2:
            return (base / 2)
        case 3:
            return base / 3
        case 4:
            return base / 4
        default:
            return base / 5
        }
    }
}

