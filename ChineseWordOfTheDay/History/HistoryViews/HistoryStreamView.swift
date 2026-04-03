import SwiftUI

struct HistoryStreamView: View {
    @ObservedObject var helper: HistoryHelper
    let startMonth: String
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    // 🔥 ALWAYS use streamSections here so the scroll isn't cut off
                    ForEach(helper.streamSections) { section in
                        monthDivider(section.monthTitle)
                            .id(section.monthTitle)
                        
                        ForEach(section.cards) { card in
                            HistoryCardDetail(card: card, isStreamMode: true)
                                .id(card.id)
                        }
                    }
                }
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Study Stream")
            .onAppear {
                // Smoothly snap to the month tapped in the main grid
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    withAnimation(.easeInOut) {
                        proxy.scrollTo(startMonth, anchor: .top)
                    }
                }
            }
        }
    }
    
    private func monthDivider(_ title: String) -> some View {
        VStack {
            Text(title.uppercased())
                .font(.system(size: 14, weight: .black, design: .rounded))
                .foregroundColor(.blue)
                .padding(.top, 60)
                .padding(.bottom, 20)
            Divider().padding(.horizontal)
        }
    }
}
