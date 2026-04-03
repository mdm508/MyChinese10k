import SwiftUI

struct HistoryCardDetail: View {
    let card: CardData
    var isStreamMode: Bool = false
    
    @Environment(\.dismiss) var dismiss
    @StateObject private var speechVM = SpeechViewModel()

    var body: some View {
        if isStreamMode {
            detailContent
        } else {
            NavigationView {
                detailContent
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { dismiss() }
                                .font(.system(size: 17, weight: .bold))
                        }
                    }
            }
        }
    }

    // --- 🧬 THE UNIFIED GUTS ---
    private var detailContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                
                // 1. --- 🐲 HERO SECTION (Inside the Card) ---
                VStack(spacing: 16) {
                    Text(card.characters)
                        .font(.system(size: 110, weight: .bold, design: .serif))
                        .foregroundColor(speechVM.isSpeaking ? .blue : .primary)
                        .scaleEffect(speechVM.isSpeaking ? 1.05 : 1.0)
                        .shadow(color: speechVM.isSpeaking ? .blue.opacity(0.15) : .clear, radius: 10)
                        .onTapGesture {
                            speechVM.speak(card.characters, .chineseTaiwan)
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                    
                    VStack(spacing: 4) {
                        Text(card.phonetic)
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        if speechVM.isSpeaking {
                            Text("Speaking...")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.blue)
                                .transition(.opacity)
                        }
                    }
                }
                .padding(.vertical, 50)
                .frame(maxWidth: .infinity)
                .background(Color.primary.opacity(0.02)) // Subtle header tint
                
                Divider()

                // 2. --- 📝 DATA SECTION (Inside the Card) ---
                VStack(alignment: .leading, spacing: 30) {
                    detailRow(title: "Meanings", content: meaningsList)
                    
                    Divider().opacity(0.5)
                    
                    HStack(alignment: .top) {
                        detailRow(title: "Index", content: Text("#\(card.wordIndex)"))
                        Spacer()
                        detailRow(title: "Learned", content: Text(formattedDate))
                    }
                }
                .padding(30)
            }
            /* --- 🎨 THE "SINGLE CARD" STYLING --- */
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(32)
            .overlay(
                RoundedRectangle(cornerRadius: 32)
                    .stroke(Color.primary.opacity(0.05), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
            /* ------------------------------------ */
            .padding(.horizontal, 20)
            .padding(.top, isStreamMode ? 0 : 20)
            .padding(.bottom, isStreamMode ? 100 : 20)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: speechVM.isSpeaking)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }
    
    // MARK: - Subviews
    
    private var meaningsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(card.meanings.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(i + 1).")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                        .foregroundColor(.blue.opacity(0.5))
                    
                    Text(card.meanings[i])
                        .font(.system(size: 19, weight: .medium, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private var formattedDate: String {
        let df = DateFormatter()
        df.dateFormat = "MMMM d, yyyy"
        return df.string(from: card.lastModified)
    }

    private func detailRow<Content: View>(title: String, content: Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.secondary.opacity(0.6))
                .kerning(1.2)
            content
        }
    }
}
