import Foundation
import SwiftUI
import Persistence
import CoreDataModels

@MainActor
class LoadingManager: ObservableObject {
    @Published var isAppLoading: Bool = true
    @Published var loadingMessage: String = "Initializing..."
    @Published var loadingProgress: Double = 0.0
    
    static let shared = LoadingManager()
    
    private init() {}
    
    func initializeApp() async {
        isAppLoading = true
        loadingProgress = 0.0
        loadingMessage = "Setting up database..."
//        deleteAll()
        loadingProgress = 0.3
        loadingMessage = "Loading Core Data..."
        
        // Wait for Core Data to be ready
        await waitForCoreDataReady()
        loadingProgress = 0.7
        loadingMessage = "Loading your progress..."
        
        // Load the initial word as part of the loading sequence
        await loadInitialWord()
        loadingProgress = 1.0
        loadingMessage = "Ready!"
        print("🔄 Loading progress: 100%")
        
        // No artificial delays - transition immediately
        isAppLoading = false
    }
    
    private func loadInitialWord() async {
        // Load the initial word as part of the loading sequence
        let context = PersistenceController.shared.context
        
        // With background notifications, we can load immediately
        // CloudKit sync happens automatically via notifications
        
        await context.perform {
            // Retrieve existing index or create a new one
            let indexObject: WordIndex
            do {
                if let existing = try context.fetch(WordIndex.fetchRequest()).first {
                    indexObject = existing
                    print("🔄 Found existing WordIndex with current: \(existing.current)")
                } else {
                    // Only create new index if we're sure CloudKit sync is complete
                    print("🔄 No WordIndex found, creating new one")
                    indexObject = WordIndex(context: context)
                    indexObject.current = 1
                    try context.save()
                }
            } catch {
                print("Failed to fetch or create WordIndex: \(error)")
                return
            }
            
            // Check total word count first
            do {
                let totalWords = try context.count(for: Word.fetchRequest())
                print("📊 Total words in database: \(totalWords)")
            } catch {
                print("❌ Error counting words: \(error)")
            }
            
            // Fetch the word at the current index
            if let word = Word.fetchWord(at: indexObject.current, context: context) {
                print("🔄 Initial word loaded: \(word.traditional) at index \(indexObject.current)")
            } else {
                print("🔄 No word found at index \(indexObject.current)")
                
                // Try to fetch the first word to see if any words exist
                if let firstWord = Word.fetchWord(at: 1, context: context) {
                    print("🔄 Found first word: \(firstWord.traditional) at index 1")
                } else {
                    print("❌ No words found in database at all!")
                }
            }
        }
    }
    
    
    private func copyDatabaseAsync() async {
        await Task.detached {
            await PersistenceController.copyDatabaseIfNeeded()
        }.value
    }
    
    private func waitForCoreDataReady() async {
        // Wait for the Core Data container to be fully loaded
        await Task.detached {
            // Access the context to ensure it's ready
            _ = await PersistenceController.shared.context
        }.value
    }
}
