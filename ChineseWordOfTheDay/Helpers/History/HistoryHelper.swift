import SwiftUI
import CoreData
import CoreDataModels
import Combine

struct HistorySection: Identifiable {
    let id = UUID()
    let monthTitle: String
    var cards: [CardData]
}

class HistoryHelper: ObservableObject {
    @Published var sections: [HistorySection] = [] // View now loops through this
    private var allCards: [CardData] = []
    @Published var searchText: String = ""
    
    let flipTrigger = PassthroughSubject<FlipAction, Never>()
    private var currentSort: SortMode = .recent
    
    enum FlipAction { case allFront, allBack, random }
    enum SortMode { case recent, indexAsc, indexDesc, shuffle }
    private let context: NSManagedObjectContext
    private var cancellables = Set<AnyCancellable>()

    init(context: NSManagedObjectContext) {
        self.context = context
        self.reload()
        
        // Settings/Search observers same as before...
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.applyFilterAndSort() }
            .store(in: &cancellables)
    }

    func reload() {
        let request: NSFetchRequest<WordStatus> = WordStatus.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]
        
        do {
            let statuses = try context.fetch(request)
            let strings = Set(statuses.compactMap { $0.traditional })
            let wordReq: NSFetchRequest<Word> = Word.fetchRequest()
            wordReq.predicate = NSPredicate(format: "traditional IN %@", strings)
            let words = try context.fetch(wordReq)
            let lookup = Dictionary(uniqueKeysWithValues: words.map { ($0.traditional, $0) })

            self.allCards = statuses.compactMap { status -> CardData? in
                guard let word = lookup[status.traditional] else { return nil }
                return CardData(status: status, word: word)
            }
            applyFilterAndSort()
        } catch { print("❌ Reload Failed: \(error)") }
    }

    private func applyFilterAndSort() {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        
        // 1. Filter
        let filtered = query.isEmpty ? allCards : allCards.filter { card in
            card.characters.contains(query) ||
            card.phonetic.lowercased().contains(query) ||
            card.displayMeaning.lowercased().contains(query) ||
            String(card.wordIndex).contains(query)
        }

        // 2. Sort the entire pool first
        let sorted: [CardData]
        switch currentSort {
        case .recent:    sorted = filtered.sorted { $0.lastModified > $1.lastModified }
        case .indexAsc:  sorted = filtered.sorted { $0.wordIndex < $1.wordIndex }
        case .indexDesc: sorted = filtered.sorted { $0.wordIndex > $1.wordIndex }
        case .shuffle:   sorted = filtered.shuffled()
        }

        // 3. Group by Month (Preserving the sort order we just created)
        // We use a helper to format the date into "October 2023"
        let grouped = Dictionary(grouping: sorted) { card in
            let formatter = DateFormatter()
            formatter.dateFormat = "MMMM yyyy"
            return formatter.string(from: card.lastModified)
        }
        
        // 4. Map to sections (We must re-sort the sections by date so October comes before September)
        self.sections = grouped.map { (key, value) in
            HistorySection(monthTitle: key, cards: value)
        }.sorted { sectionA, sectionB in
            // Sort sections by the date of the first card in each
            (sectionA.cards.first?.lastModified ?? Date()) > (sectionB.cards.first?.lastModified ?? Date())
        }
    }
    
    // MARK: Public API
    
    /// flip all cards to some side based on the given `action`. 
    func bulkFlip(_ action: FlipAction) {
            // 1. Update the 'isFlipped' state on the actual data
            for sectionIndex in sections.indices {
                for cardIndex in sections[sectionIndex].cards.indices {
                    switch action {
                    case .allFront:
                        sections[sectionIndex].cards[cardIndex].isFlipped = false
                    case .allBack:
                        sections[sectionIndex].cards[cardIndex].isFlipped = true
                    case .random:
                        sections[sectionIndex].cards[cardIndex].isFlipped = Bool.random()
                    }
                }
            }
            
            // 2. We still send the trigger for the animation of visible cards
            flipTrigger.send(action)
        }
    func sortByRecent() { currentSort = .recent; applyFilterAndSort() }
    func sortByIndex(ascending: Bool) { currentSort = ascending ? .indexAsc : .indexDesc; applyFilterAndSort() }
    func shuffleCards() { currentSort = .shuffle; applyFilterAndSort() }
}
