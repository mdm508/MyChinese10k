import SwiftUI
import CoreDataModels
import Combine

struct HistoryCard: View {
    let status: WordStatus
    let flipPublisher: PassthroughSubject<HistoryHelper.FlipAction, Never>
    
    @Environment(\.managedObjectContext) var context
    @State private var isFlipped = false
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
                    if !isFlipped {
                        frontView(word: word)
                    } else {
                        backView(word: word)
                    }
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        isFlipped.toggle()
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
                .fill(Color(red: 0.92, green: 0.96, blue: 1.0)) // Icey Blue
            
            VStack {
                // Fallback check for empty .characters
                Text(word.characters.isEmpty ? word.traditional : word.characters)
                    .font(.system(size: 36, weight: .bold, design: .serif))
                    .foregroundColor(Color(red: 0.2, green: 0.3, blue: 0.5))
                
                Text("LVL \(status.status)")
                    .font(.system(size: 8, weight: .black))
                    .padding(4)
                    .background(Color.black.opacity(0.05))
                    .cornerRadius(4)
            }
        }
    }
    
    private func backView(word: Word) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color(red: 0.94, green: 0.98, blue: 0.94)) // Pastel Green
            
            VStack(spacing: 4) {
                Text(word.phonetic.isEmpty ? word.pinyin : word.phonetic)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(Color(red: 0.2, green: 0.4, blue: 0.2))
                
                // Horizontal meanings scroller
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(word.meanings, id: \.self) { m in
                            Text(m)
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .padding(.horizontal, 8)
                        }
                    }
                }
                
                Text("#\(status.index)")
                    .font(.system(size: 9, weight: .black, design: .monospaced))
                    .opacity(0.2)
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
            case .allFront: isFlipped = false
            case .allBack: isFlipped = true
            case .random: isFlipped = Bool.random()
            }
        }
    }
}
