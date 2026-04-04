import SwiftUI
import CoreData
import CoreDataModels

struct HistoryView: View {
    // 🎯 Use EnvironmentObject - injected at App level
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
                        
                        // 1. Month Chips
                        monthFilterBar
                        
                        // 2. The Main Grid
                        LazyVGrid(columns: columns, spacing: 16, pinnedViews: [.sectionHeaders]) {
                            ForEach(helper.sections, id: \.name) { section in
                                Section(header: sectionHeader(section.name)) {
                                    
                                    let statuses = section.objects as? [WordStatus] ?? []
                                    
                                    ForEach(statuses, id: \.objectID) { status in
                                        HistoryCard(
                                            status: status,
                                            flipPublisher: helper.flipTrigger
                                        )
                                    }
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.top)
                }
            }// ... inside HistoryView body, attached to the ZStack ...
            .navigationBarTitleDisplayMode(.inline) // 🎯 Keep the bar slim
            .toolbar {
                // 🛠️ CENTER: The Title (Locked on the same line as the back button)
                ToolbarItem(placement: .principal) {
                    Text("HISTORY")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.terracotta.opacity(0.7))
                        .kerning(2)
                }

                // 🛠️ RIGHT: Your Tools
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
                // FIXED: Direct access to helper.allAvailableMonths (no $)
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
        // 🔗 THE HEADER LINK: Pointing to the Streamer
        NavigationLink(destination: HistoryStreamView(helper: helper, startMonth: title)) {
            HStack {
                Text(helper.formatFullMonth(title))
                    .font(.system(size: 14, weight: .black, design: .rounded))
                    .foregroundColor(.forestGreen.opacity(0.7))
                    .kerning(2)
                
                Spacer()
                
                // ⚡️ The "Stream" Indicator
                Image(systemName: "bolt.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.terracotta.opacity(0.5))
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.forestGreen.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color.pastelGreen.opacity(0.15)) // Sexy subtle bar
            .contentShape(Rectangle()) // 🛡️ Makes the WHOLE bar tappable, not just the text
        }
        .buttonStyle(PlainButtonStyle()) // 🛡️ Stops the header from turning blue
    }

    private var bulkFlipMenu: some View {
        Menu {
            Button("Characters Only") { helper.bulkFlip(.allFront) }
            Button("Meanings Only") { helper.bulkFlip(.allBack) }
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
