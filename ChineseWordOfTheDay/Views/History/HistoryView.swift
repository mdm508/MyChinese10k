import SwiftUI
import CoreData
import CoreDataModels

struct HistoryView: View {
    @StateObject var helper: HistoryHelper
    
    // Grid layout: 3 columns with 12pt spacing
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationView {
            ScrollView {
                // pinnedViews makes the Month headers stick to the top as you scroll
                LazyVGrid(columns: columns, spacing: 12, pinnedViews: [.sectionHeaders]) {
                    ForEach(helper.sections) { section in
                        Section(header: monthHeader(section.monthTitle)) {
                            ForEach(section.cards) { card in
                                HistoryCard(card: card, flipPublisher: helper.flipTrigger)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color(uiColor: .systemGroupedBackground))
            .navigationTitle("History")
            .searchable(text: $helper.searchText, prompt: "Search index, pinyin, or meaning")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    mainMenu
                }
            }
        }
        .navigationViewStyle(.stack)
    }

    // MARK: - Subviews

    private var mainMenu: some View {
        Menu {
            Section("Bulk Flip") {
                Button { helper.bulkFlip(.allFront) } label: {
                    Label("Show Characters", systemImage: "a.square")
                }
                Button { helper.bulkFlip(.allBack) } label: {
                    Label("Show Meanings", systemImage: "character.book.closed")
                }
                Button { helper.bulkFlip(.random) } label: {
                    Label("Random Flip", systemImage: "dice")
                }
            }
            
            Section("Sort & Shuffle") {
                Button { helper.sortByRecent() } label: {
                    Label("Most Recent", systemImage: "clock")
                }
                Button { helper.sortByIndex(ascending: true) } label: {
                    Label("Index: Low to High", systemImage: "arrow.up")
                }
                Button { helper.sortByIndex(ascending: false) } label: {
                    Label("Index: High to Low", systemImage: "arrow.down")
                }
                Button { helper.shuffleCards() } label: {
                    Label("Shuffle All", systemImage: "shuffle")
                }
            }
        } label: {
            Image(systemName: "ellipsis.circle")
                .font(.title3)
        }
    }

    private func monthHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.bold())
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)
            // Use a background with a blur or opacity to make the "pinned" effect look native
            .background(Color(uiColor: .systemGroupedBackground).opacity(0.95))
    }
}
