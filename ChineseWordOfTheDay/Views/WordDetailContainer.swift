//
//  WordDetailContainer.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 6/9/25.
//

import SwiftUI
import CoreDataModels
import CoreData

/// A container view responsible for fetching and presenting the "Word of the Day".
/// If no word remains, it displays a congratulations message.
struct WordDetailContainer {
    // MARK: - Environment & Fetch Request

    /// Core Data context for fetch/save operations
    @Environment(\.managedObjectContext) private var context

    /// Fetches the single WordIndex record, sorted by its `current` property
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \WordIndex.current, ascending: true)]
    )
    private var wordIndexResults: FetchedResults<WordIndex>

    /// Convenient accessor for the fetched WordIndex
    private var wordIndex: WordIndex? {
        wordIndexResults.first
    }

    // MARK: - State

    /// The currently displayed WordRepresentable, loaded asynchronously
    @State private var word: WordRepresentable = MockWord.placeholder
    // MARK: - Initialization

    /// Customizes the FetchRequest to limit results to 1 and sort by `current`
    init() {
        let request: NSFetchRequest<WordIndex> = WordIndex.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [
            NSSortDescriptor(keyPath: \WordIndex.current, ascending: true)
        ]
        _wordIndexResults = FetchRequest(fetchRequest: request)
    }
}

// MARK: - View Conformance

extension WordDetailContainer: View {
    var body: some View {
        Group {
            if word.index != MockWord.placeholder.index {
                // Display the detail view, passing in the nextWord action
                WordDetail(word: self.$word, onNext: nextWord)
            } else {
                // Fallback when all words have been completed
                Text("Congratulations! You have completed all the words!")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        // Trigger loading when this view appears
        .onAppear {
            Task { await loadCurrentWord() }
        }
    }
}

// MARK: - Data Loading & Actions

extension WordDetailContainer {
    /// Loads or initializes the WordIndex and fetches the corresponding Word
    private func loadCurrentWord() async {
        await context.perform {
            // Retrieve existing index or create a new one
            let indexObject: WordIndex
            if let existing = wordIndexResults.first {
                indexObject = existing
            } else {
                indexObject = WordIndex(context: context)
                indexObject.current = 1
                do {
                    try context.save()
                } catch {
                    print("Failed to save WordIndex: \(error)")
                }
            }

            // Fetch the word at the current index
            self.word = Word.fetchWord(at: indexObject.current, context: context) ?? MockWord.placeholder
        }
    }

    /// Advances to the next word, saves changes, marks the previous word as seen, and reloads
    func nextWord() async {
        guard let indexObject = wordIndex else { return }

        // Increment index and save
        indexObject.current += 1
        do {
            try context.save()
        } catch {
            print("Failed to save incremented WordIndex: \(error)")
        }

        // Update status and fetch the next word
        Task {
            if let word = word as? Word {
                await updateCurrentWordStatusToSeen(word: word, context: context)
            }
            await loadCurrentWord()
        }
    }
}
