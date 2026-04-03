import SwiftUI
import Combine

struct HistoryCard: View {
    let card: CardData
    let flipPublisher: PassthroughSubject<HistoryHelper.FlipAction, Never>
    
    // Internal state that drives the rotation animation
    @State private var isFlipped: Bool

    // Explicit init to sync the View's local state with the Data Source's state
    init(card: CardData, flipPublisher: PassthroughSubject<HistoryHelper.FlipAction, Never>) {
        self.card = card
        self.flipPublisher = flipPublisher
        // Sets the initial flip state based on what the Helper decided (random, front, or back)
        self._isFlipped = State(initialValue: card.isFlipped)
    }

    var body: some View {
        ZStack {
            frontSide.opacity(isFlipped ? 0 : 1)
            
            backSide.opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (0, 1, 0))
        }
        .aspectRatio(1, contentMode: .fit)
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (0, 1, 0))
        
        // Manual flip on tap
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                isFlipped.toggle()
            }
        }
        
        // --- 1. THE BROADCAST (For visible cards) ---
        .onReceive(flipPublisher) { _ in
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                // Sync with the master state updated in HistoryHelper
                isFlipped = card.isFlipped
            }
        }
        
        // --- 2. THE RECOVERY (For recycled cards) ---
        .onAppear {
            // When scrolling, ensure the card looks like its data says it should
            isFlipped = card.isFlipped
        }
        
        // --- 3. THE SWAP (For data changes) ---
        .onChange(of: card.id) { _ in
            // If the grid swaps this view's data, update the flip state immediately
            isFlipped = card.isFlipped
        }
    }

    // MARK: - Subviews

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
                Text(card.displayMeaning)
                    .font(.subheadline).bold()
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 4)
                Text(card.phonetic)
                    .font(.system(size: 10, weight: .black))
                    .padding(4)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(4)
                    .minimumScaleFactor(0.5)
                Spacer()
            }
        }
    }
}
