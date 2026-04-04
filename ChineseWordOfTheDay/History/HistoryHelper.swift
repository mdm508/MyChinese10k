import SwiftUI
import Combine
import CoreData
import CoreDataModels

// MARK: - Supporting Types
struct HistorySection: Identifiable {
    // 🔥 FIX: Use the monthTitle as the ID.
    // This prevents SwiftUI from destroying/recreating sections when filters change.
    var id: String { monthTitle }
    let monthTitle: String
    var cards: [CardData]
}

// MARK: - Main Class Declaration
class HistoryHelper: ObservableObject {
    // Persistent Properties
    internal let context: NSManagedObjectContext
    internal var cancellables = Set<AnyCancellable>()
    internal var allCards: [CardData] = []
    
    // UI State Properties
    @Published var sections: [HistorySection] = []
    @Published var searchText: String = ""
    @Published var allAvailableMonths: [String] = []
    @Published var selectedMonths: Set<String> = []
    
    // Commands & Logic State
    internal var currentSort: SortMode = .recent
    let flipTrigger = PassthroughSubject<FlipAction, Never>()
    
    enum FlipAction { case allFront, allBack, random }
    enum SortMode { case recent, indexAsc, indexDesc, shuffle }

    // MARK: - Static Formatters
    // Using static formatters is 100x faster than creating them inside loops
    private static let filterFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMM, ''yy"
        return df
    }()

    private static let headerFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        return df
    }()

    init(context: NSManagedObjectContext) {
        self.context = context
        self.setupSearchObserver()
        self.reload()
    }
}

// MARK: - Extension: Data Loading
extension HistoryHelper {
    func reload() {
        let request: NSFetchRequest<WordStatus> = WordStatus.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(key: "lastModified", ascending: false)]
        
        do {
            let statuses = try context.fetch(request)
            let strings = statuses.compactMap { $0.traditional }
            
            // Fetch the actual word data using the 'traditional' string bridge
            let wordReq: NSFetchRequest<Word> = Word.fetchRequest()
            wordReq.predicate = NSPredicate(format: "traditional IN %@", strings)
            let words = try context.fetch(wordReq)
            
            // Create a lookup dictionary for O(1) matching speed
            let lookup = Dictionary(words.map { ($0.traditional ?? "", $0) },
                                 uniquingKeysWith: { first, _ in first })

            // Join the two entities into our UI-friendly CardData
            self.allCards = statuses.compactMap { status -> CardData? in
                // Since status.traditional is already a String, we just check the lookup
                guard let word = lookup[status.traditional] else {
                    return nil
                }
                return CardData(status: status, word: word)
            }
            
            self.updateAvailableMonths()
            self.applyFilterAndSort()
            
        } catch {
            print("❌ Reload Failed: \(error)")
        }
    }
}

// MARK: - Extension: Filtering & Search
extension HistoryHelper {
    internal func setupSearchObserver() {
        $searchText
            .removeDuplicates()
            .debounce(for: .milliseconds(150), scheduler: RunLoop.main)
            .sink { [weak self] _ in self?.applyFilterAndSort() }
            .store(in: &cancellables)
    }

    internal func applyFilterAndSort() {
        let query = searchText.lowercased().trimmingCharacters(in: .whitespaces)
        
        // 1. Filter: Checks multi-select months AND search text
        let filtered = allCards.filter { card in
            let cardMonthLabel = Self.filterFormatter.string(from: card.lastModified)
            
            // Fix: Logic now properly allows multiple months to exist in the set
            let matchesMonth = selectedMonths.isEmpty || selectedMonths.contains(cardMonthLabel)
            
            let matchesSearch = query.isEmpty || (
                card.characters.contains(query) ||
                card.phonetic.lowercased().contains(query) ||
                card.displayMeaning.lowercased().contains(query) ||
                String(card.wordIndex).contains(query)
            )
            return matchesMonth && matchesSearch
        }

        // 2. Sort the pool
        let sorted = performSort(on: filtered)

        // 3. Group into Sections using Full Month (August 2026)
        let grouped = Dictionary(grouping: sorted) { card in
            Self.headerFormatter.string(from: card.lastModified)
        }
        
        // 4. Update Published sections
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            self.sections = grouped.map { HistorySection(monthTitle: $0.key, cards: $0.value) }
                .sorted { (sectionA, sectionB) in
                    let dateA = sectionA.cards.first?.lastModified ?? Date.distantPast
                    let dateB = sectionB.cards.first?.lastModified ?? Date.distantPast
                    return dateA > dateB
                }
        }
    }

    func toggleMonthFilter(_ month: String) {
        if selectedMonths.contains(month) {
            selectedMonths.remove(month)
        } else {
            selectedMonths.insert(month)
        }
        applyFilterAndSort()
    }
    
    func clearMonthFilters() {
        selectedMonths.removeAll()
        applyFilterAndSort()
    }
}

// MARK: - Extension: Sorting Logic
extension HistoryHelper {
    private func performSort(on cards: [CardData]) -> [CardData] {
        switch currentSort {
        case .recent:    return cards.sorted { $0.lastModified > $1.lastModified }
        case .indexAsc:  return cards.sorted { $0.wordIndex < $1.wordIndex }
        case .indexDesc: return cards.sorted { $0.wordIndex > $1.wordIndex }
        case .shuffle:   return cards.shuffled()
        }
    }

    func sortByRecent() {
        currentSort = .recent
        applyFilterAndSort()
    }
    
    func sortByIndex(ascending: Bool) {
        currentSort = ascending ? .indexAsc : .indexDesc
        applyFilterAndSort()
    }
    
    func shuffleCards() {
        currentSort = .shuffle
        applyFilterAndSort()
    }
}

// MARK: - Extension: Batch Actions
extension HistoryHelper {
    func bulkFlip(_ action: FlipAction) {
        // This updates the data source
        for sIdx in sections.indices {
            for cIdx in sections[sIdx].cards.indices {
                switch action {
                case .allFront: sections[sIdx].cards[cIdx].isFlipped = false
                case .allBack:  sections[sIdx].cards[cIdx].isFlipped = true
                case .random:   sections[sIdx].cards[cIdx].isFlipped = Bool.random()
                }
            }
        }
        // This triggers the publisher for the UI cards to animate
        flipTrigger.send(action)
    }
}

// MARK: - Extension: Internal Helpers
extension HistoryHelper {
    private func updateAvailableMonths() {
        // Collect all unique "Aug, '26" strings found in the current history
        let months = allCards.map { Self.filterFormatter.string(from: $0.lastModified) }
        var uniqueMonths: [String] = []
        
        for month in months where !uniqueMonths.contains(month) {
            uniqueMonths.append(month)
        }
        self.allAvailableMonths = uniqueMonths
    }
}
