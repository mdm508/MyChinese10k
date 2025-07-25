//
//  WordView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 6/16/23.
// 'id like to fit tha characters into that space'

import SwiftUI
import CoreDataModels

struct WordView {
    @Binding var word: String
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
    struct PreviewWrapper: View {
        @State var mockWord = MockWord.placeholder.traditional
        var body: some View {
            GeometryReaderCentered { geo in
                WordView(word: $mockWord, size: geo.size)
            }
        }
    }
    static var previews: some View {
        PreviewWrapper()
    }
}
