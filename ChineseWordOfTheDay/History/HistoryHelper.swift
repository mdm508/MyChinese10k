import SwiftUI
import Combine

class HistoryHelper: ObservableObject {
    @Published var searchText: String = ""
    @Published var selectedMonths: Set<String> = []
    @Published var allCards: [CardData] = []
    
    let flipTrigger = PassthroughSubject<FlipAction, Never>()
    enum FlipAction { case allFront, allBack, random }

    // 🎯 GRID DATA: Respects Search AND Month Filters
    var sections: [CardSection] {
        let filtered = applySearch(to: allCards)
        let grouped = Dictionary(grouping: filtered) { $0.monthTitle }
        
        return grouped.map { CardSection(monthTitle: $0.key, cards: $0.value) }
            .filter { section in
                selectedMonths.isEmpty || selectedMonths.contains(section.monthTitle)
            }
            .sorted { $0.date > $1.date }
    }

    // 🌊 STREAM DATA: Respects Search but IGNORES Month Filters (for infinite scroll)
    var streamSections: [CardSection] {
        let filtered = applySearch(to: allCards)
        let grouped = Dictionary(grouping: filtered) { $0.monthTitle }
        
        return grouped.map { CardSection(monthTitle: $0.key, cards: $0.value) }
            .sorted { $0.date > $1.date }
    }

    var allAvailableMonths: [String] {
        let months = Set(allCards.map { $0.monthTitle })
        return months.sorted { monthSortDate(for: $0) > monthSortDate(for: $1) }
    }

    func toggleMonthFilter(_ month: String) {
        if selectedMonths.contains(month) {
            selectedMonths.remove(month)
        } else {
            selectedMonths.insert(month)
        }
    }

    func clearMonthFilters() {
        selectedMonths.removeAll()
    }

    private func applySearch(to cards: [CardData]) -> [CardData] {
        if searchText.isEmpty { return cards }
        return cards.filter {
            $0.characters.contains(searchText) ||
            $0.phonetic.lowercased().contains(searchText.lowercased()) ||
            $0.displayMeaning.lowercased().contains(searchText.lowercased())
        }
    }
    
    private func monthSortDate(for title: String) -> Date {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        return df.date(from: title) ?? Date.distantPast
    }

    // Standard Helper Methods
    func sortByRecent() { allCards.sort { $0.lastModified > $1.lastModified } }
    func shuffleCards() { allCards.shuffle() }
    func bulkFlip(_ action: FlipAction) { flipTrigger.send(action) }
}

struct CardSection: Identifiable {
    let id = UUID()
    let monthTitle: String
    let cards: [CardData]
    var date: Date {
        let df = DateFormatter()
        df.dateFormat = "MMMM yyyy"
        return df.date(from: monthTitle) ?? Date()
    }
}
