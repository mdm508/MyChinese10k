import SwiftUI
import CoreData
import CoreDataModels

struct HistoryView: View {
    @EnvironmentObject var helper: HistoryHelper
    @Environment(\.managedObjectContext) var viewContext
    
    private let columns = [
        GridItem(.adaptive(minimum: 100), spacing: 16)
    ]
    
    var body: some View {
        ZStack {
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    monthFilterBar
                    
                    LazyVGrid(columns: columns, spacing: 16, pinnedViews: [.sectionHeaders]) {
                        // 🛠️ FIX: Added 'id: \.name' to satisfy the compiler
                        ForEach(helper.sections, id: \.name) { section in
                            Section(header: sectionHeader(section.name)) {
                                
                                let statuses = section.objects as? [WordStatus] ?? []
                                
                                ForEach(statuses, id: \.objectID) { status in
                                    // 🛠️ FIX: Removed flipPublisher (Card now gets it from Environment)
                                    HistoryCard(status: status)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.top)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("HISTORY")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.terracotta.opacity(0.7))
                    .kerning(2)
            }

            ToolbarItemGroup(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    bulkFlipMenu
                    sortMenu
                }
                .foregroundColor(.forestGreen)
            }
        }
    }
}

// MARK: - Subviews Extension
extension HistoryView {
    
    private var monthFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(helper.allAvailableMonths, id: \.self) { month in
                    let isSelected = helper.selectedMonths.contains(month)
                    
                    Text(helper.formatShortMonth(month))
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(isSelected ? Color.blue : Color(UIColor.secondarySystemGroupedBackground))
                        .foregroundColor(isSelected ? .white : .blue)
                        .cornerRadius(12)
                        .onTapGesture {
                            withAnimation(.spring()) {
                                helper.toggleMonthFilter(month)
                            }
                        }
                }
            }
            .padding(.horizontal)
        }
    }
    
    private func sectionHeader(_ title: String) -> some View {
        NavigationLink(destination: HistoryStreamView(helper: helper, startMonth: title)) {
            HStack {
                Text(helper.formatFullMonth(title))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.forestGreen.opacity(0.7))
                    .kerning(2)
                
                Spacer()
                
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.terracotta.opacity(0.5))
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.forestGreen.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.pastelGreen.opacity(0.15))
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }

    private var bulkFlipMenu: some View {
        Menu {
            // 🛠️ FIX: Updated enum cases to .front and .back
            Button("Characters Only") { helper.bulkFlip(.front) }
            Button("Meanings Only") { helper.bulkFlip(.back) }
            Button("Random Mix") { helper.bulkFlip(.random) }
        } label: {
            Image(systemName: "square.stack.3d.down.right")
        }
    }

    private var sortMenu: some View {
        Menu {
            Button("Time Learned") { helper.updateSort(.recent) }
            Button("Index Asc (0-9)") { helper.updateSort(.indexAsc) }
            Button("Index Desc (9-0)") { helper.updateSort(.indexDesc) }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
        }
    }
}
