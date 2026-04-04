import SwiftUI
import CoreData
import Combine
import CoreDataModels

struct HistoryView: View {
    @StateObject var helper: HistoryHelper
    
    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        VStack(spacing: 0) {
            monthFilterBar
            
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12, pinnedViews: [.sectionHeaders]) {
                    ForEach(helper.sections, id: \.name) { section in
                        Section(header: monthHeader(section.name)) {
                            let statuses = section.objects as? [WordStatus] ?? []
                            
                            ForEach(statuses, id: \.objectID) { (status: WordStatus) in
                                HistoryCardBridge(
                                    status: status,
                                    flipTrigger: helper.flipTrigger
                                )
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
        .searchable(text: $helper.searchText, prompt: "Search index or characters")
    }
}

// MARK: - The Bridge (Fetches Word Data)
struct HistoryCardBridge: View {
    let status: WordStatus
    let flipTrigger: PassthroughSubject<HistoryHelper.FlipAction, Never>
    
    @Environment(\.managedObjectContext) var context
    
    // Lazy lookup for the dictionary content
    private var word: Word? {
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        request.predicate = NSPredicate(format: "index == %d", status.index)
        request.fetchLimit = 1
        return try? context.fetch(request).first
    }
    
    var body: some View {
        HistoryCard(
            status: status,
            characters: word?.traditional ?? "",
            meaning: word?.meanings.first ?? "",
            flipPublisher: flipTrigger
        )
    }
}

// MARK: - Visual Card Component
struct HistoryCard: View {
    let status: WordStatus
    let characters: String
    let meaning: String
    let flipPublisher: PassthroughSubject<HistoryHelper.FlipAction, Never>
    
    @State private var isFlipped = false
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(UIColor.secondarySystemGroupedBackground))
                .shadow(color: .black.opacity(0.05), radius: 2)
            
            VStack(spacing: 4) {
                if !isFlipped {
                    Text(characters)
                        .font(.system(size: 28, weight: .bold, design: .serif))
                } else {
                    Text(meaning)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .multilineTextAlignment(.center)
                        .padding(4)
                }
                
                Text("#\(status.index)")
                    .font(.system(size: 9, weight: .black))
                    .opacity(0.2)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onReceive(flipPublisher) { action in
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                switch action {
                case .allFront: isFlipped = false
                case .allBack: isFlipped = true
                case .random: isFlipped = Bool.random()
                }
            }
        }
    }
}

// MARK: - View Extensions
extension HistoryView {
    private var monthFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(helper.allAvailableMonths, id: \.self) { monthID in
                    let isSelected = helper.selectedMonths.contains(monthID)
                    Text(monthID) // Simplified label
                        .font(.system(size: 12, weight: .bold))
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(isSelected ? Color.blue : Color.secondary.opacity(0.1))
                        .foregroundColor(isSelected ? .white : .primary)
                        .clipShape(Capsule())
                        .onTapGesture { helper.toggleMonthFilter(monthID) }
                }
            }
            .padding(8)
        }
        .background(Color(UIColor.secondarySystemGroupedBackground))
    }
    
    private func monthHeader(_ name: String) -> some View {
        Text(name.uppercased())
            .font(.system(size: 11, weight: .black))
            .foregroundColor(.blue)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemGroupedBackground))
    }
}
