import SwiftUI

struct HistoryStreamView: View {
    @ObservedObject var helper: HistoryHelper
    let startMonth: String
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(helper.sections) { section in
                        // The Date Header
                        monthDivider(section.monthTitle)
                            .id(section.monthTitle)
                        
                        ForEach(section.cards) { card in
                            // 🔥 Streaming the exact same Detail view!
                            HistoryCardDetail(card: card, isStreamMode: true)
                                .id(card.id)
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("History Stream")
            .onAppear {
                proxy.scrollTo(startMonth, anchor: .top)
            }
        }
    }
    
    private func monthDivider(_ title: String) -> some View {
        VStack {
            Text(title.uppercased())
                .font(.system(size: 14, weight: .black))
                .foregroundColor(.blue)
                .padding(.vertical, 60)
            Divider()
        }
    }
}
