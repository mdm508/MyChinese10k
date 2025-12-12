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
    /// View model for handling all data operations and display preferences
    @State private var word: WordRepresentable = MockWord.placeholder
    @State private var wordIndex: WordIndex?
    @State private var phoneticText: String = ""
    @State private var hanziText: String = ""
    @State private var isRefreshing: Bool = false
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
        // Load current word immediately since loading screen should have prepared everything
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
            
            WordView(word: hanziText, size: geo.size)
            Text(phoneticText)
                .font(.headline)

            meaningsList

            nextButton(in: geo)
        }
        .padding()
        .task {
            await updateDisplay(for: word)
        }
        .onChange(of: word.index) { _ in
            Task {
                await updateDisplay(for: word)
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
    @MainActor
    func updateDisplay(for word: WordRepresentable) async {
        // Update phonetic based on user preferences
        if await UserPreferences.get(.phoneticNotation) == .zhuyin {
            phoneticText = word.zhuyin
        } else {
            phoneticText = word.pinyin
        }
        // Update hanzi based on user preferences
        if await UserPreferences.get(.chineseWritingSystem) == .traditional {
            hanziText = word.traditional
        } else {
            hanziText = word.simplified
        }
    }
    
    func loadCurrentIndex() -> Void {
        if self.wordIndex != nil {
            return
        }
        do {
            if let existing = try self.context.fetch(WordIndex.fetchRequest()).first {
                self.wordIndex = existing
            } else {
                // only called first time app created
                let indexObject = WordIndex(context: self.context)
                indexObject.current = 1
                self.wordIndex = indexObject
                try self.context.save()
            }
        } catch {
            print("Failed to fetch or create WordIndex: \(error)")
            return
        }
    }
    func getCurrentIndex()  -> Int64{
        self.loadCurrentIndex()
        return self.wordIndex!.current
    }
    func incrementIndex(){
        self.loadCurrentIndex()
        self.wordIndex!.current += 1
        try! self.context.save()
    }
    func loadCurrentWord() async {
        let fetchedWord = Word.fetchWord(at: self.getCurrentIndex(), context: self.context)!
        self.word = fetchedWord
        await updateDisplay(for: self.word)
    }
    
    func nextWord() async {
        self.incrementIndex()
        await loadCurrentWord()
    }
    
    
}
