import SwiftUI
import CoreData
import CoreDataModels

struct HistoryStreamView: View {
    @ObservedObject var helper: HistoryHelper
    let startMonth: String
    @Environment(\.managedObjectContext) var viewContext
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(helper.sections, id: \.name) { section in
                        monthDivider(section.name)
                            .id(section.name)
                        let statuses = section.objects as? [WordStatus] ?? []
                        ForEach(statuses, id: \.objectID) { status in
                            if let word = Word.fetchWord(at: status.index, context: viewContext) {
                                HistoryCardDetail(
                                    status: status,
                                    word: word,
                                    isStreamMode: true
                                )
                                .id(status.objectID)
                                .padding(.vertical, 12)
                            }
                        }
                    }
                }
            }
            .background(Color.pastelGreen.opacity(0.15).ignoresSafeArea())
            .navigationTitle("History Stream")
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.spring(response: 0.8, dampingFraction: 0.8)) {
                        proxy.scrollTo(startMonth, anchor: .top)
                    }
                }
            }
        }
    }
}
// MARK: - Subviews & Styling
extension HistoryStreamView {
    private func monthDivider(_ identifier: String) -> some View {
        VStack(spacing: 15) {
            Text(formatFullMonth(identifier))
                .font(.system(size: 13, weight: .black, design: .rounded))
                .foregroundColor(.forestGreen.opacity(0.4))
                .kerning(5)
                .padding(.top, 120)
            /// Sexy custom line for August/September transitions
            HStack(spacing: 10) {
                Rectangle()
                    .fill(
                        LinearGradient(colors: [.clear, .terracotta.opacity(0.3)], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 1)
                
                Image(systemName: "sparkles")
                    .font(.system(size: 10))
                    .foregroundColor(.terracotta.opacity(0.5))
                
                Rectangle()
                    .fill(
                        LinearGradient(colors: [.terracotta.opacity(0.3), .clear], startPoint: .leading, endPoint: .trailing)
                    )
                    .frame(height: 1)
            }
            .padding(.horizontal, 50)
            .padding(.bottom, 60)
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
