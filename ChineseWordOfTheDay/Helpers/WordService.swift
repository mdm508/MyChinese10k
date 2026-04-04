import Foundation
import CoreData
import CoreDataModels
import Persistence
import Combine
import WidgetKit

final class WordService: ObservableObject {
    private let context: NSManagedObjectContext
    
    @Published var currentIndex: Int64!
    @Published var currentWord: Word!
    private var cancellables: Set<AnyCancellable> = []
    
    var maxIndex: Int64 {
        (Word.maxIndex(context: context) ?? 0) + 1
    }

    init(context: NSManagedObjectContext) {
        self.context = context
        self.fetchAndSetCurrentWordAndIndex()
        
        // Listen for CloudKit/Remote changes
        NotificationCenter.default.publisher(for: .cdcksStoreDidChange)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.fetchAndSetCurrentWordAndIndex()
            }
            .store(in: &cancellables)
    }

    /// Marks the word as seen, moves to next index, and refreshes state.
    @discardableResult
    func markWordAsSeen() -> Bool {
        do {
            try upsertWordStatus(for: self.currentWord, to: .seen)
            try incrementCurrentWordIndex()
            try context.save()
            
            fetchAndSetCurrentWordAndIndex()
            return true
        } catch {
            print("❌ Error updating status or index: \(error)")
            return false
        }
    }

    /// Refreshes the local published properties.
    private func fetchAndSetCurrentWordAndIndex() {
        let index = self.fetchCurrentIndex()
        self.currentIndex = index
        
        if let fetchedWord = Word.fetchWord(at: index, context: self.context) {
            self.currentWord = fetchedWord
            self.syncWidget()
        } else {
            // Logically, we should always find a word if the index is valid
            print("⚠️ No word found at index \(index)")
        }
    }

    // MARK: - Internal Logic

    private func fetchCurrentIndex() -> Int64 {
        let request: NSFetchRequest<WordIndex> = WordIndex.fetchRequest()
        request.fetchLimit = 1
        
        do {
            if let existing = try context.fetch(request).first {
                return existing.current
            } else {
                let newIndex = WordIndex(context: context)
                newIndex.current = 1
                newIndex.lastModified = Date()
                try context.save()
                return 1
            }
        } catch {
            print("❌ Failed to fetch Index: \(error)")
            return 1
        }
    }

    private func upsertWordStatus(for word: Word, to status: LearnStatus) throws {
        let request: NSFetchRequest<WordStatus> = WordStatus.fetchRequest()
        request.predicate = NSPredicate(format: "index == %d", word.index)
        request.fetchLimit = 1
        
        let wordStatus = try context.fetch(request).first ?? WordStatus(context: context)
        let now = Date()
        
        if wordStatus.isInserted {
            wordStatus.index = word.index
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM"
            wordStatus.sectionIdentifier = formatter.string(from: now)
        }
        
        wordStatus.status = status.rawValue
        wordStatus.lastModified = now
    }

    private func incrementCurrentWordIndex() throws {
        let request: NSFetchRequest<WordIndex> = WordIndex.fetchRequest()
        let indexObject = try context.fetch(request).first ?? WordIndex(context: context)
        indexObject.current += 1
        indexObject.lastModified = Date()
    }

    private func syncWidget() {
        // Because MockWord/Widget data uses the protocol,
        // writeToUserDefaults will now grab the dynamic characters automatically.
        self.currentWord.writeToUserDefaults()
        WidgetCenter.shared.reloadAllTimelines()
    }
}

extension WordService {
    /// Views can call this to force a refresh if necessary (e.g., manual settings toggle)
    public func settingsUpdated() {
        fetchAndSetCurrentWordAndIndex()
    }
}
