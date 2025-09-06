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
struct WordDetail {
    // MARK: - State

    /// View model for handling all data operations and display preferences
    @EnvironmentObject var displayViewModel: WordDisplayViewModel
}

// MARK: - View Conformance
extension WordDetail: View {
    var body: some View {
        Group {
            if displayViewModel.word.index != MockWord.placeholder.index {
                // Display the word details - everything should be ready from loading screen
                GeometryReaderCentered { geo in
                    ZStack {
                        content(in: geo)
                        
                        // Show loading indicator when refreshing from CloudKit
                        if displayViewModel.isRefreshing {
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.2)
                                Text("Syncing latest...")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding()
                            .background(Color.black.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
            } else {
                // Fallback when all words have been completed
                Text("Congratulations! You have completed all the words!")
                    .font(.title2)
                    .multilineTextAlignment(.center)
                    .padding()
            }
        }
        // Load current word immediately since loading screen should have prepared everything
        .onAppear {
            Task { await displayViewModel.loadCurrentWord() }
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
                currentIndex: Int(displayViewModel.word.index), 
                size: geo.size,
                context: PersistenceController.shared.context
            )
                .padding(.horizontal)
                .padding(.bottom, 8)
            
            WordView(word: displayViewModel.hanziText, size: geo.size)
            Text(displayViewModel.phoneticText)
                .font(.headline)

            meaningsList

            nextButton(in: geo)
        }
        .padding()
        .task {
            await displayViewModel.updateDisplay(for: displayViewModel.word)
        }
        .onChange(of: displayViewModel.word.index) { _ in
            Task {
                await displayViewModel.updateDisplay(for: displayViewModel.word)
            }
        }
    }

    /// A scrollable list of the word's meanings.
    var meaningsList: some View {
        List(displayViewModel.word.meanings, id: \.self) { meaning in
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
                    await displayViewModel.nextWord()
                }
            }
            .disabled(displayViewModel.isProcessingNextWord)
            .opacity(displayViewModel.isProcessingNextWord ? 0.6 : 1.0)
            .padding(.bottom, 40)
        }
    }
}

// MARK: - View Model

@MainActor
class WordDisplayViewModel: ObservableObject, CurrentWordRefreshDelegate {
    @Published var word: WordRepresentable = MockWord.placeholder
    @Published var phoneticText: String = ""
    @Published var hanziText: String = ""
    @Published var isRefreshing: Bool = false
    
    private let context: NSManagedObjectContext
    @Published var isProcessingNextWord = false // Prevent concurrent saves
    
    init(context: NSManagedObjectContext) {
        self.context = context
    }
    
    func updateDisplay(for word: WordRepresentable) async {
        // Update phonetic based on user preferences
        if await UserPreferences.get(.phoneticNotation) == .zhuyin {
            self.phoneticText = word.zhuyin
        } else {
            self.phoneticText = word.pinyin
        }
        
        // Update hanzi based on user preferences
        if await UserPreferences.get(.chineseWritingSystem) == .traditional {
            self.hanziText = word.traditional
        } else {
            self.hanziText = word.simplified
        }
    }
    
    func loadCurrentWord() async {
        await context.perform {
            // Retrieve existing index or create a new one
            let indexObject: WordIndex
            do {
                if let existing = try self.context.fetch(WordIndex.fetchRequest()).first {
                    indexObject = existing
                } else {
                    indexObject = WordIndex(context: self.context)
                    indexObject.current = 1
                    try self.context.save()
                }
            } catch {
                print("Failed to fetch or create WordIndex: \(error)")
                return
            }
            
            // Fetch the word at the current index
            self.word = Word.fetchWord(at: indexObject.current, context: self.context) ?? MockWord.placeholder
            
            // Update display
            Task {
                await self.updateDisplay(for: self.word)
            }
        }
    }
    
    func nextWord() async {
        // Prevent concurrent saves
        guard !isProcessingNextWord else { 
            print("⚠️ nextWord() called while already processing - ignoring")
            return 
        }
        
        isProcessingNextWord = true
        print("🔄 Starting nextWord() - current index: \(word.index)")
        
        defer { 
            isProcessingNextWord = false
            print("🔄 Finished nextWord() - isProcessingNextWord reset to false")
        }
        
        await context.perform {
            do {
                guard let indexObject = try self.context.fetch(WordIndex.fetchRequest()).first else { 
                    print("❌ No WordIndex found")
                    return 
                }

                // Increment index and save
                let oldIndex = indexObject.current
                indexObject.current += 1
                try self.context.save()
                print("🔄 Incremented index from \(oldIndex) to \(indexObject.current)")

                // Update status for the previous word
                if let word = self.word as? Word {
                    Task {
                        await updateCurrentWordStatusToSeen(word: word, context: self.context)
                    }
                }
                
                // Fetch the new word using the updated index
                let newIndex = indexObject.current
                if let newWord = Word.fetchWord(at: newIndex, context: self.context) {
                    // Update on main actor to ensure UI updates
                    Task { @MainActor in
                        self.word = newWord
                        print("🔄 Updated word on main actor: \(newWord.traditional) at index \(newIndex)")
                        
                        // Force UI update
                        self.objectWillChange.send()
                        
                        // Small delay to prevent UI from being overwhelmed
                        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 second
                    }
                } else {
                    print("❌ No word found at index \(newIndex)")
                    Task { @MainActor in
                        self.word = MockWord.placeholder
                        self.objectWillChange.send()
                    }
                }
            } catch {
                print("❌ Failed to advance to next word: \(error)")
            }
        }
    }
    
    // MARK: - CurrentWordRefreshDelegate
    
    nonisolated func refresh() {
        print("🔄 Refreshing current word due to CloudKit notification")
        
        Task { @MainActor in
            isRefreshing = true
            
            await context.perform {
                // Force refresh the current word from the updated index
                if let indexObject = try? self.context.fetch(WordIndex.fetchRequest()).first {
                    let newWord: WordRepresentable = Word.fetchWord(at: indexObject.current, context: self.context) ?? MockWord.placeholder
                    
                    // Update the word and display on main actor
                    Task { @MainActor in
                        self.word = newWord
                        print("🔄 Refreshed to word: \(newWord.traditional) at index \(indexObject.current)")
                        
                        // Update display preferences
                        await self.updateDisplay(for: newWord)
                        self.isRefreshing = false
                    }
                } else {
                    Task { @MainActor in
                        self.isRefreshing = false
                    }
                }
            }
        }
    }
}
