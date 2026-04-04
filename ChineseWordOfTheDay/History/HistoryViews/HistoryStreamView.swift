import SwiftUI
import CoreData
import CoreDataModels

struct HistoryStreamView: View {
    @ObservedObject var helper: HistoryHelper
    let startMonth: String
    
    // We need the context to pass it down to HistoryCardDetail for its internal Word fetch
    @Environment(\.managedObjectContext) var viewContext
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(helper.sections, id: \.name) { section in
                        // The Date Header (section.name is "2026-04")
                        monthDivider(section.name)
                            .id(section.name)
                        
                        let statuses = section.objects as? [WordStatus] ?? []
                        
                        ForEach(statuses, id: \.objectID) { (status: WordStatus) in
                            // 🔥 Streaming the updated Detail view!
                            HistoryCardDetail(
                                status: status,
                                context: viewContext,
                                isStreamMode: true
                            )
                            .id(status.objectID)
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("History Stream")
            .onAppear {
                // Scroll to the specific month the user tapped from the grid
                proxy.scrollTo(startMonth, anchor: .top)
            }
        }
    }
    
    private func monthDivider(_ identifier: String) -> some View {
        let displayTitle = formatFullMonth(identifier)
        
        return VStack {
            Text(displayTitle)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(.blue)
                .kerning(2)
                .padding(.vertical, 60)
            Divider()
        }
    }

    private func formatFullMonth(_ id: String) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        guard let date = formatter.date(from: id) else { return id }
        
        let out = DateFormatter()
        out.dateFormat = "MMMM yyyy"
        return out.string(from: date).uppercased()
    }
}
