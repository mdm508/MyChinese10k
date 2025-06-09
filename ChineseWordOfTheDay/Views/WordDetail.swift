//
//  WordDetailView.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 6/9/25.
//

import SwiftUI
import CoreDataModels

struct WordDetail {
    var word: WordRepresentable
}
extension WordDetail: View {
    var body: some View {
        GeometryReaderCentered { geo in
            VStack(alignment: .center) {
                WordView(word: currentWord.traditional, size: geo.size)
                Text(currentWord.zhuyin)
                ZStack(alignment: .bottomTrailing) {
                    List(currentWord.meanings, id: \.self) {
                        Text($0)
                    }
                    HStack {
                        Spacer()
                        BigGreenButton(parentSize: geo.size) {
                            if let wi = self.wordIndex {
                                wi.current += 1
                                try! context.save()
                                Task {
                                    if let w = self.currentWord {
                                        await updateCurrentWordStatusToSeen(word: w, context: self.context)
                                        await self.loadCurrentWord()
                                    }
                                }
                            }

                        }
                    }.background(Color.clear)
                }
            }
        }
    }
}
