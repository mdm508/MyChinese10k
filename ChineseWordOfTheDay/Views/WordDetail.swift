//
//  WordDetailView.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 6/9/25.
//

import SwiftUI
import CoreDataModels
import Persistence
import CoreData

/**
 Displays the current Word. If all word's have been completed exits.
 */
@MainActor
struct WordDetail {
    // MARK: - State
    @EnvironmentObject private var ws: WordService
    @State private var isProcessingNextWord = false
}

// MARK: - Body Definition
extension WordDetail: View {
    var body: some View {
        Group {
            if ws.currentWord.index < ws.maxIndex {
                GeometryReaderCentered { geo in
                    ZStack {
                        content(in: geo)
                    }
                }
            } else {
                // Fallback when all words have been completed
                Text("Congratulations! You've learned all the words!")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
    }
}
// MARK: - Layout & Subviews
private extension WordDetail {
    /// The main content layout inside the GeometryReader.
    func content(in geo: GeometryProxy) -> some View {
        VStack(alignment: .center) {
            // Learning progress bar
            Text(ws.currentWord.phonetic) // or word.phonetic if you add it to MockWord
                .font(.headline)
        #if DEBUG
            Text("\(self.ws.currentWord.index)")
                .font(.body)
        #endif
            WordView(word: ws.currentWord.characters, size: geo.size) // or word.characters if you add it
            meaningsList

            nextButton(in: geo)
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: .settingDidChange),
                   perform: {_ in ws.settingsUpdated()})
    }
    /// A scrollable list of the word's meanings.
    var meaningsList: some View {
        List(ws.currentWord.meanings, id: \.self) { meaning in
            Text(meaning)
        }
        .listStyle(.plain)
    }
    /// The Next button centered at the bottom.
    func nextButton(in geo: GeometryProxy) -> some View {
        VStack {
            Spacer()
            BigGreenButton(parentSize: geo.size) {
                ws.markWordAsSeen()
            }
            .disabled(isProcessingNextWord)
            .opacity(isProcessingNextWord ? 0.6 : 1.0)
            .padding(.bottom, 40)
        }
    }
}
