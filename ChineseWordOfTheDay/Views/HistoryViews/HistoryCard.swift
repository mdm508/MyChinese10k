import SwiftUI
import Combine
import AVFoundation

struct HistoryCard: View {
    // MARK: - Properties
    let card: CardData
    let flipPublisher: PassthroughSubject<HistoryHelper.FlipAction, Never>
    
    @State private var isFlipped: Bool
    @State private var meaningIndex: Int = 0
    @State private var showingDetail = false
    @State private var dragOffset: CGFloat = 0

    // MARK: - Initialization
    init(card: CardData, flipPublisher: PassthroughSubject<HistoryHelper.FlipAction, Never>) {
        self.card = card
        self.flipPublisher = flipPublisher
        // Sync local state with model state for initial render
        self._isFlipped = State(initialValue: card.isFlipped)
    }

    var body: some View {
        mainCardContent
            .sheet(isPresented: $showingDetail) {
                CardDetailModal(card: card)
            }
    }
}

// MARK: - Extension: View Layout
extension HistoryCard {
    private var mainCardContent: some View {
        ZStack {
            frontSide.opacity(isFlipped ? 0 : 1)
            
            backSide.opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (0, 1, 0))
        }
        .aspectRatio(1, contentMode: .fit)
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (0, 1, 0))
        .gesture(cardGestures)
        .onReceive(flipPublisher) { _ in syncFlipState(animated: true) }
        .onAppear { syncFlipState(animated: false) }
        .onChange(of: card.id) { _ in syncFlipState(animated: false) }
    }
}

// MARK: - Extension: Gestures
extension HistoryCard {
    private var cardGestures: some Gesture {
        // 1. Long Press -> Detail Modal
        LongPressGesture(minimumDuration: 0.5)
            .onEnded { _ in
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                showingDetail = true
            }
            // 2. Tap -> Flip
            .simultaneously(with: TapGesture().onEnded {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    isFlipped.toggle()
                }
            })
            // 3. Swipe -> Change Meaning (Backside only)
            .simultaneously(with: DragGesture()
                .onChanged { value in
                    if isFlipped { dragOffset = value.translation.width }
                }
                .onEnded { value in
                    if isFlipped { handleSwipe(width: value.translation.width) }
                    withAnimation(.interactiveSpring()) { dragOffset = 0 }
                }
            )
    }
    
    private func handleSwipe(width: CGFloat) {
        guard card.meanings.count > 1 else { return }
        
        if abs(width) > 50 { // Threshold
            withAnimation(.spring()) {
                if width < 0 { // Next
                    meaningIndex = (meaningIndex + 1) % card.meanings.count
                } else { // Previous
                    meaningIndex = (meaningIndex - 1 + card.meanings.count) % card.meanings.count
                }
            }
        }
    }
}

// MARK: - Extension: Card Faces
extension HistoryCard {
    private var frontSide: some View {
        CardFace(color: Color.blue.opacity(0.05)) {
            HistoryWordView(text: card.characters)
        }
    }

    private var backSide: some View {
        CardFace(color: Color.orange.opacity(0.05)) {
            VStack(spacing: 4) {
                Spacer()
                
                // Active Meaning (Swappable)
                Text(card.meanings[safe: meaningIndex] ?? card.displayMeaning)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)
                    .minimumScaleFactor(0.7)
                    .id("\(card.id)\(meaningIndex)")
                
                Text(card.phonetic)
                    .font(.system(size: 9, weight: .black))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.12))
                    .cornerRadius(4)
                
                // Multi-meaning Dots
                if card.meanings.count > 1 {
                    HStack(spacing: 3) {
                        ForEach(0..<card.meanings.count, id: \.self) { index in
                            Circle()
                                .fill(index == meaningIndex ? Color.orange : Color.secondary.opacity(0.3))
                                .frame(width: 4, height: 4)
                        }
                    }
                }
                
                Spacer()
            }
            .offset(x: dragOffset * 0.4) // Subtle feedback
        }
    }
}

// MARK: - Extension: Logic Sync
extension HistoryCard {
    private func syncFlipState(animated: Bool) {
        if animated {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                isFlipped = card.isFlipped
            }
        } else {
            isFlipped = card.isFlipped
        }
        meaningIndex = 0 // Reset scroll position when recycling
    }
}

