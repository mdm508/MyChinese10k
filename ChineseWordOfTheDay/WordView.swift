//
//  WordView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 6/16/23.
//

import SwiftUI

struct WordView {
    var word: String
    var size:  CGSize
}

extension WordView: View {
    var body: some View {
        Text(self.word)
            .font(.system(size: fontSize()))
            .lineLimit(1)
    }
}
extension WordView {
    static let scalingFactor: CGFloat = 0.8
    func fontSize() -> CGFloat {
        let spaceAvailable = min(self.size.width, self.size.height) * Self.scalingFactor
        let sizePerCharacter = spaceAvailable / CGFloat(self.word.count)
        return sizePerCharacter
    }
}
struct ChineseCharacter_Previews: PreviewProvider {
    static var previews: some View {
        GeometryReaderCentered { geo in
            WordView(word: "翻譯", size: geo.size)
        }
    }
}


