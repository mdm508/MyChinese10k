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

/// A view that displays a single word's details and handles navigation to the next word.
/// If no word remains, it displays a congratulations message.
@MainActor
struct WordDetail {
    // MARK: - State
    @State private var word: WordRepresentable = MockWord.placeholder
    @State private var isProcessingNextWord = false
    private let context = PersistenceController.shared.context
}

// MARK: - View Conformance
extension WordDetail: View {
    var body: some View {
        Group {
            if word.index != MockWord.placeholder.index {
                // Display the word details - everything should be ready from loading screen
                GeometryReaderCentered { geo in
                    ZStack {
                        content(in: geo)
                    }
                }
            } else {
                // Fallback when all words have been completed
                Text("Loading")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        .onAppear {
            Task { await loadCurrentWord() }
        }
    }
}

// MARK: - Layout & Subviews

private extension WordDetail {
    /// The main content layout inside the GeometryReader.
    func content(in geo: GeometryProxy) -> some View {
        VStack(alignment: .center) {
            // Learning progress bar
            LearningProgressBar(
                currentIndex: Int(word.index),
                size: geo.size,
                context: PersistenceController.shared.context
            )
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            WordView(word: word.characters, size: geo.size)
            Text(word.phonetic)
                .font(.headline)

            meaningsList

            nextButton(in: geo)
        }
        .padding()
        .task {
            await loadCurrentWord()
        }
        .onChange(of: word.index) { _ in
            Task {
                await loadCurrentWord()
            }
        }
    }

    /// A scrollable list of the word's meanings.
    var meaningsList: some View {
        List(word.meanings, id: \.self) { meaning in
            Text(meaning)
        }
        .listStyle(.plain)
    }

    /// The Next button centered at the bottom.
    func nextButton(in geo: GeometryProxy) -> some View {
        VStack {
            Spacer()
            BigGreenButton(parentSize: geo.size) {
                Task {
                    await nextWord()
                }
            }
            .disabled(isProcessingNextWord)
            .opacity(isProcessingNextWord ? 0.6 : 1.0)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - Async Logic

extension WordDetail {
    /// Fetches the current word then updates the display.
    func loadCurrentWord() async {
        let ws = WordService(context: self.context)
        await self.word = ws.loadCurrentWord()
    }
    /// Marks the current word as known and loads the next word.
    func nextWord() async {
        let ws = WordService(context: self.context)
        await ws.markWordAsSeen(self.word)
        await loadCurrentWord()
    }
    
    
}

