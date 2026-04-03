import SwiftUI
import CoreData
import CoreDataModels

struct HistoryView: View {
    @StateObject var helper: HistoryHelper
    
    // Grid layout configuration
    internal let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            // Horizontal Month Filter Bar
            monthFilterBar
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12, pinnedViews: [.sectionHeaders]) {
                    ForEach(helper.sections) { section in
                        Section(header: monthHeader(section.monthTitle)) {
                            ForEach(section.cards) { card in
                                HistoryCard(card: card, flipPublisher: helper.flipTrigger)
                            }
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
        }
        .background(Color(UIColor.systemGroupedBackground))
        .navigationTitle("History")
        .navigationBarTitleDisplayMode(.inline)
        // iOS 15 compliant searchable
        .searchable(text: $helper.searchText, prompt: "Search index, pinyin, or meaning")
        .toolbar {
            // iOS 15 uses navigationBarTrailing instead of topBarTrailing
            ToolbarItem(placement: .navigationBarTrailing) {
                mainMenu
            }
        }
    }
}

// MARK: - Extension: Filter Bar Components
extension HistoryView {
    private var monthFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(helper.allAvailableMonths, id: \.self) { month in
                    monthToggleChip(for: month)
                }
                
                if !helper.selectedMonths.isEmpty {
                    clearFilterButton
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
        .overlay(
            VStack {
                Spacer()
                Divider()
            }
        )
    }
    
    private func monthToggleChip(for month: String) -> some View {
        let isSelected = helper.selectedMonths.contains(month)
        
        return Text(month)
            // iOS 15 safe font weight
            .font(.system(size: 12, weight: .bold, design: .rounded))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(isSelected ? Color.blue : Color.secondary.opacity(0.12))
            .foregroundColor(isSelected ? .white : .primary)
            .clipShape(Capsule())
            .onTapGesture {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                    helper.toggleMonthFilter(month)
                }
            }
    }
    
    private var clearFilterButton: some View {
        Button {
            withAnimation { helper.clearMonthFilters() }
        } label: {
            Image(systemName: "xmark.circle.fill")
                .foregroundColor(.secondary) // Replaced foregroundStyle
                .font(.body)
        }
    }
}

// MARK: - Extension: Menu & Navigation
extension HistoryView {
    internal var mainMenu: some View {
        Menu {
            Section {
                Button { helper.bulkFlip(.allFront) } label: {
                    Label("Characters", systemImage: "a.square")
                }
                Button { helper.bulkFlip(.allBack) } label: {
                    Label("Meanings", systemImage: "character.book.closed")
                }
                Button { helper.bulkFlip(.random) } label: {
                    Label("Random", systemImage: "dice")
                }
            }
            
            Section {
                Button { helper.sortByRecent() } label: {
                    Label("Recent", systemImage: "clock")
                }
                Button { helper.shuffleCards() } label: {
                    Label("Shuffle", systemImage: "shuffle")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.system(size: 18, weight: .semibold)) // Safe weight
        }
    }
}

// MARK: - Extension: Section Headers
extension HistoryView {
    internal func monthHeader(_ title: String) -> some View {
        // 🔗 Tapping the header now "Dives In"
        NavigationLink(destination: HistoryStreamView(helper: helper, startMonth: title)) {
            HStack {
                Text(title.uppercased())
                    .font(.system(size: 11, weight: .black, design: .rounded))
                    .foregroundColor(.blue) // Color cue that it's tappable
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.secondary.opacity(0.5))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Capsule().fill(Color(UIColor.secondarySystemGroupedBackground)))
            .padding(.vertical, 8)
        }
        .buttonStyle(PlainButtonStyle()) // Keeps it from looking like a standard blue button
    }
}
