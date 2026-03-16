//
//  ResizingCharacterText.swift
//  ChineseWordOfTheDay
//
//  Created by m on 3/15/26.
//


import SwiftUI

struct ResizingCharacterText: View {
    let characters: String

    var body: some View {
        Text(characters)
            .font(.system(size: fontSizeForCharacterCount(), weight: .bold, design: .default))
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .allowsTightening(true)
            .frame(maxWidth: .infinity, alignment: .center)
    }

    private func fontSizeForCharacterCount() -> CGFloat {
        let count = max(characters.count, 1)

        switch count {
        case 1:
            return 68
        case 2:
            return 58
        case 3:
            return 48
        default:
            return 38
        }
    }
}
