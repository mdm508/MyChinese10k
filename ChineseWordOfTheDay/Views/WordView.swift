//
//  WordView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 6/16/23.
// 'id like to fit tha characters into that space'

import SwiftUI

struct WordView {
    var word: String
    var size:  CGSize
}

extension WordView: View {
    var body: some View {
        Text(self.word)
            .font(.system(size: 100))
            .multilineTextAlignment(.center) // Center-align the text

    }
}
extension WordView {
    static let scalingFactor: CGFloat = 0.5
    func fontSize() -> CGFloat {
        let spaceAvailable = min(self.size.width, self.size.height) * Self.scalingFactor
        let sizePerCharacter = spaceAvailable / CGFloat(self.word.count)
        return sizePerCharacter
    }
}
struct ChineseCharacter_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReaderCentered { geo in
            WordView(word: "一發不可收拾", size: geo.size)
        }
    }
}


/*
 Testing data
 Traditional: 一發不可收拾, Frequency: 7 6
 Traditional: 不可同日而語, Frequency: 0 6
 Traditional: 二氧化碳, Frequency: 108 4
 Traditional: 不好意思, Frequency: 69 4
 */
