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
            // Background color for the whole gallery
            Color(UIColor.systemGroupedBackground).ignoresSafeArea()
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    monthFilterBar
                    LazyVGrid(columns: columns, spacing: 16, pinnedViews: [.sectionHeaders]) {
                        ForEach(helper.sections, id: \.name) { section in
                            // Only show headers in Timeline mode. Index modes show one giant list.
                            Section(header: helper.currentSort == .recent ? sectionHeader(section.name) : nil) {
                                let statuses = section.objects as? [WordStatus] ?? []
                                
                                ForEach(statuses, id: \.objectID) { status in
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
                HStack(spacing: 12) {
                    if helper.isFiltered {
                        Button(action: { helper.resetToDefaults() }) {
                            Image(systemName: "arrow.counterclockwise.circle.fill")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.terracotta)
                        }
                        .transition(.scale.combined(with: .opacity))
                    }
                    bulkFlipMenu
                    sortMenu
                }
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
                        .background(isSelected ? Color.forestGreen : Color(UIColor.secondarySystemGroupedBackground))
                        .foregroundColor(isSelected ? .white : .forestGreen)
                        .cornerRadius(12)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
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
            Button { helper.bulkFlip(.front) } label: {
                Label("Show All Characters", systemImage: "character.cursor.ibeam")
            }
            Button { helper.bulkFlip(.back) } label: {
                Label("Show All Meanings", systemImage: "doc.text.magnifyingglass")
            }
            Divider()
            Button { helper.bulkFlip(.random) } label: {
                Label("Random Flips", systemImage: "shuffle")
            }
        } label: {
            Image(systemName: "square.3.layers.3d.down.right")
                .foregroundColor(.forestGreen)
        }
    }
    private var sortMenu: some View {
        Menu {
            Button { helper.updateSort(.recent) } label: {
                Label("Timeline", systemImage: "calendar.badge.clock")
            }
            Button { helper.updateSort(.indexAsc) } label: {
                Label("Number (1-9)", systemImage: "textformat.123")
            }
            Button { helper.updateSort(.indexDesc) } label: {
                Label("Number (9-1)", systemImage: "arrow.down.to.line")
            }
        } label: {
            Image(systemName: "arrow.up.arrow.down")
                .foregroundColor(.forestGreen)
        }
    }
}
