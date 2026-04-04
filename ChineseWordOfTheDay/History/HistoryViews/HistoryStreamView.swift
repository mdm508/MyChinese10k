import SwiftUI
import CoreData
import CoreDataModels

struct HistoryStreamView: View {
    @ObservedObject var helper: HistoryHelper
    let startMonth: String // Expecting "yyyy-MM" format
    
    @Environment(\.managedObjectContext) var viewContext
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(helper.sections, id: \.name) { section in
                        // Section Header (e.g., APRIL 2026)
                        monthDivider(section.name)
                            .id(section.name)
                        
                        let statuses = section.objects as? [WordStatus] ?? []
                        
                        ForEach(statuses, id: \.objectID) { status in
                            // 🎯 The Stream Bridge: Fetch the word for this row
                            if let word = fetchWord(for: status) {
                                HistoryCardDetail(
                                    status: status,
                                    word: word,
                                    isStreamMode: true
                                )
                                .id(status.objectID)
                            }
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("History Stream")
            .onAppear {
                // Slight delay for iOS 15 ScrollViewReader reliability
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring()) {
                        proxy.scrollTo(startMonth, anchor: .top)
                    }
                }
            }
        }
    }
    
    // MARK: - Internal Helper
    
    private func fetchWord(for status: WordStatus) -> Word? {
        let request: NSFetchRequest<Word> = Word.fetchRequest()
        request.predicate = NSPredicate(format: "index == %d", status.index)
        request.fetchLimit = 1
        return try? viewContext.fetch(request).first
    }
    
    // MARK: - Subviews
    
    private func monthDivider(_ identifier: String) -> some View {
        let displayTitle = formatFullMonth(identifier)
        
        return VStack(spacing: 0) {
            Text(displayTitle)
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(.blue)
                .kerning(2)
                .padding(.vertical, 80)
            
            Divider()
                .padding(.horizontal, 40)
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
