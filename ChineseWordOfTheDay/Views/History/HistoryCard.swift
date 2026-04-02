import SwiftUI
import Combine

struct HistoryCard: View {
    let card: CardData
    let flipPublisher: PassthroughSubject<HistoryHelper.FlipAction, Never>
    @State private var isFlipped: Bool = false
    
    var body: some View {
        ZStack {
            frontSide.opacity(isFlipped ? 0 : 1)
            backSide.opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (0, 1, 0))
        }
        .aspectRatio(1, contentMode: .fit)
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (0, 1, 0))
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isFlipped.toggle()
            }
        }
        // Listen for Bulk Commands
        .onReceive(flipPublisher) { action in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                switch action {
                case .allFront: isFlipped = false
                case .allBack:  isFlipped = true
                case .random:   isFlipped = Bool.random()
                }
            }

        }
        .onChange(of: card.id) { _ in
            isFlipped = false
        }
    }
    
    private var frontSide: some View {
        CardFace(color: .blue.opacity(0.05)) {
            VStack {
                Spacer()
                HistoryWordView(text: card.characters)
                Spacer()
            }
        }
    }
    
    private var backSide: some View {
        CardFace(color: .orange.opacity(0.05)) {
            VStack(spacing: 8) {
                Spacer()
                Text(card.characters)
                Text(card.displayMeaning)
                    .font(.subheadline).bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
                Text("\(card.phonetic)")
                    .font(.system(size: 8, weight: .black))
                    .padding(4).background(Color.secondary.opacity(0.1)).cornerRadius(4)
                Spacer()
            }
        }
    }
}
