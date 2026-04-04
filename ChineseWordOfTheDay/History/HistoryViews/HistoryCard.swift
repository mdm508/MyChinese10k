import SwiftUI
import CoreDataModels
import Combine

struct HistoryCard: View {
    let status: WordStatus
    let flipPublisher: PassthroughSubject<HistoryHelper.FlipAction, Never>
    
    @Environment(\.managedObjectContext) var context
    @State private var isShowingFront = true
    @State private var showDetail = false
    
    // 🎯 Self-Fetching Logic with Debugging
    private var word: Word? {
        let fetched = Word.fetchWord(at: status.index, context: context)
        
        // Debugging empty characters issue
        if let w = fetched {
            if w.characters.isEmpty {
                print("⚠️ [HistoryCard] Index #\(status.index) has EMPTY .characters. Trad: '\(w.traditional)'")
            }
        } else {
            print("❌ [HistoryCard] No Word found for Index #\(status.index)")
        }
        
        return fetched
    }

    var body: some View {
        Group {
            if let word = word {
                ZStack {
                        frontView(word: word)
                            .rotation3DEffect(.degrees(isShowingFront ? 0 : -180), axis: (x: 0, y: 1, z: 0))
                            .opacity(isShowingFront ? 1 : 0)
                        backView(word: word)
                            .rotation3DEffect(.degrees(isShowingFront ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                            .opacity(isShowingFront ? 0 : 1)
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isShowingFront.toggle()
                    }
                    UISelectionFeedbackGenerator().selectionChanged()
                }
                .onLongPressGesture(minimumDuration: 0.5) {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    showDetail = true
                }
            } else {
                errorPlaceholder
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .onReceive(flipPublisher) { action in
            handleBulkFlip(action)
        }
        .sheet(isPresented: $showDetail) {
            if let word = word {
                HistoryCardDetail(status: status, word: word)
            }
        }
    }
}

// MARK: - Card Faces
extension HistoryCard {
    private func frontView(word: Word) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.orangeDream) // Soft Peach/Orange
            VStack {
                // Fallback check for empty .characters
                Text(word.characters)
                    .font(.system(.largeTitle))
                    .foregroundColor(Color.terracotta)
                
            }
        }
    }
    
    private func backView(word: Word) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.pastelGreen)
            
            VStack(alignment: .leading, spacing: 4) {
                let syllables = word.phonetic.components(separatedBy: " ").filter { !$0.isEmpty }
                VStack(spacing: -2) { // Tight spacing for a professional "block" look
                    ForEach(syllables, id: \.self) { syllable in
                        Text(syllable)
                            .font(.title2)
                            .foregroundColor(Color.forestGreen)
                            .bold()
                            .padding(.vertical, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .minimumScaleFactor(0.5) // 🛡️ Shrinks the whole stack if there are too many syllables
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(word.meanings, id: \.self) { m in
                            Text(m)
                                .font(.footnote)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 4)
                                .cornerRadius(8)
                                .background(
                                                Capsule()
                                                    .fill(Color.white.opacity(0.6))
                                                    .shadow(color: .black.opacity(0.05), radius: 1, x: 0, y: 1)
                                            )
                        }
                    }
                    .padding(.horizontal, 10)
                }
                .mask(
                    HStack(spacing: 0) {
                        // Left fade
                        LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .leading, endPoint: .trailing)
                            .frame(width: 15)
                        // Solid middle
                        Rectangle().fill(Color.black)
                        // Right fade
                        LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .leading, endPoint: .trailing)
                            .frame(width: 15)
                    }
                )
            }
            .padding(8)
        }
    }
    
    private var errorPlaceholder: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.red.opacity(0.1))
            .overlay(Image(systemName: "exclamationmark.triangle").foregroundColor(.red))
    }
    
    private func handleBulkFlip(_ action: HistoryHelper.FlipAction) {
        withAnimation(.spring()) {
            switch action {
            case .allFront: isShowingFront = false
            case .allBack: isShowingFront = true
            case .random: isShowingFront = Bool.random()
            }
        }
    }
}

extension Color {
    // --- Front Card (Warm/Peach) ---
    static let orangeDream = Color(red: 1.0, green: 0.96, blue: 0.92)
    static let terracotta = Color(red: 0.7, green: 0.35, blue: 0.15)
    
    // --- Back Card (Cool/Green) ---
    static let pastelGreen = Color(red: 0.94, green: 0.98, blue: 0.94)
    static let forestGreen = Color(red: 0.1, green: 0.3, blue: 0.1)
}
