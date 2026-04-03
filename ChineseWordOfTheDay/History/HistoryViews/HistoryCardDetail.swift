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

    private var detailContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // 🐲 HERO SECTION (Character & Phonetic)
                VStack(spacing: 16) {
                    Text(card.characters)
                        .font(.system(size: 110, weight: .bold, design: .serif))
                        .foregroundColor(speechVM.isSpeaking ? .blue : .primary)
                        .scaleEffect(speechVM.isSpeaking ? 1.05 : 1.0)
                        .onTapGesture {
                            speechVM.speak(card.characters, .chineseTaiwan)
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                    
                    Text(card.phonetic)
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .padding(.vertical, 50)
                .frame(maxWidth: .infinity)
                .background(Color.primary.opacity(0.02))
                
                Divider()

                // 📝 DATA SECTION (Meanings & Info)
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
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(32)
            .overlay(RoundedRectangle(cornerRadius: 32).stroke(Color.primary.opacity(0.05), lineWidth: 1))
            .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, isStreamMode ? 100 : 20)
        }
        .background(Color(UIColor.systemGroupedBackground))
    }

    private var meaningsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            ForEach(card.meanings.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: 10) {
                    Text("\(i + 1).").font(.system(size: 18, weight: .black)).foregroundColor(.blue.opacity(0.5))
                    Text(card.meanings[i]).font(.system(size: 19, weight: .medium))
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
            Text(title.uppercased()).font(.system(size: 11, weight: .black)).foregroundColor(.secondary.opacity(0.6)).kerning(1.2)
            content
        }
    }
}
