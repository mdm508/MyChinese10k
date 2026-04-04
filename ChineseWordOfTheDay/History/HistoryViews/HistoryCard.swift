import SwiftUI
import CoreDataModels
import Combine

struct HistoryCard: View {
    @EnvironmentObject var helper: HistoryHelper // 🧠 The Brain
    let status: WordStatus
    
    @Environment(\.managedObjectContext) var context
    @State private var showDetail = false
    
    // 🧐 SELECTIVE HEARING: The card only cares about its specific ID in the ledger
    private var isShowingFront: Bool {
        // If the ledger doesn't have the ID yet, we default to showing the front (false = not flipped)
        !(helper.flipStates[status.objectID] ?? false)
    }

    // 🎯 Self-Fetching Logic
    private var word: Word? {
        let fetched = Word.fetchWord(at: status.index, context: context)
        if fetched == nil {
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
                        .overlay(alignment: .topLeading) {
                            Text("\(status.index)")
                                .font(.system(size: 10, weight: .bold, design: .monospaced))
                                .foregroundColor(isShowingFront ? Color.terracotta.opacity(0.3) : Color.forestGreen.opacity(0.3))
                                .padding([.top, .leading], 10)
                        }
                    
                    backView(word: word)
                        .rotation3DEffect(.degrees(isShowingFront ? 180 : 0), axis: (x: 0, y: 1, z: 0))
                        .opacity(isShowingFront ? 0 : 1)
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                        // 🗣️ Talk back to the Boss!
                        helper.toggleFlip(for: status.objectID)
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
        // 🗑️ REMOVED: .onReceive(flipPublisher) - We don't need to listen anymore!
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
                .fill(Color.orangeDream)
            VStack {
                Text(word.characters)
                    .font(.system(size: 40, weight: .bold, design: .serif)) // Cleaned up styling
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
                
                VStack(spacing: -2) {
                    // 🛠️ FIX: Use indices instead of \.self to handle duplicate sounds
                    ForEach(syllables.indices, id: \.self) { index in
                        Text(syllables[index])
                            .font(.title2)
                            .foregroundColor(Color.forestGreen)
                            .bold()
                            .padding(.vertical, 2)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .minimumScaleFactor(0.5)
                
                // Do the same for meanings just in case!
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(word.meanings.indices, id: \.self) { index in
                            Text(word.meanings[index])
                                .font(.system(size: 10, weight: .bold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color.white.opacity(0.6)))
                                .foregroundColor(.forestGreen)
                        }
                    }
                    .padding(.horizontal, 10)
                }
            }
            .padding(8)
        }
    }
    
    private var errorPlaceholder: some View {
        RoundedRectangle(cornerRadius: 18)
            .fill(Color.red.opacity(0.1))
            .overlay(Image(systemName: "exclamationmark.triangle").foregroundColor(.red))
    }
}
