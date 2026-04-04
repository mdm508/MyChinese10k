import SwiftUI
import CoreData
import CoreDataModels

struct HistoryCardDetail: View {
    // 🎯 CLEANER CONTRACT: Just the objects we care about
    let status: WordStatus
    let word: Word
    var isStreamMode: Bool = false
    
    // Grab context from the air if we need to save changes (e.g. updating status)
    @Environment(\.managedObjectContext) var context
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
                
                // --- 🐲 HERO SECTION (Icey Blue) ---
                VStack(spacing: 16) {
                    Text(word.characters)
                        .font(.system(size: 110, weight: .bold, design: .serif))
                        .foregroundColor(speechVM.isSpeaking ? .blue : Color(red: 0.2, green: 0.3, blue: 0.5))
                        .scaleEffect(speechVM.isSpeaking ? 1.05 : 1.0)
                        .onTapGesture {
                            speechVM.speak(word.characters, .chineseTaiwan)
                            UISelectionFeedbackGenerator().selectionChanged()
                        }
                    
                    VStack(spacing: 4) {
                        Text(word.phonetic)
                            .font(.system(size: 26, weight: .bold, design: .rounded))
                            .foregroundColor(.secondary)
                        
                        if speechVM.isSpeaking {
                            Text("SPEAKING")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.blue)
                        }
                    }
                }
                .padding(.vertical, 60)
                .frame(maxWidth: .infinity)
                .background(Color(red: 0.92, green: 0.96, blue: 1.0)) // Icey Blue Hero
                
                // --- 📝 DATA SECTION (Pastel Green Base) ---
                VStack(alignment: .leading, spacing: 32) {
                    
                    // Meanings with Horizontal Scroll internal support
                    VStack(alignment: .leading, spacing: 12) {
                        headerLabel("Definitions")
                        meaningsList
                    }
                    
                    Divider().opacity(0.5)
                    
                    // Metadata Row
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 8) {
                            headerLabel("Index")
                            Text("#\(status.index)")
                                .font(.system(size: 20, weight: .bold, design: .monospaced))
                        }
                        Spacer()
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        headerLabel("Learned Date")
                        Text(formattedDate)
                            .font(.system(size: 17, weight: .medium, design: .rounded))
                    }
                }
                .padding(30)
                .background(Color(red: 0.94, green: 0.98, blue: 0.94).opacity(0.5)) // Faded Pastel Green
            }
            .background(Color(UIColor.secondarySystemGroupedBackground))
            .cornerRadius(32)
            .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
        }
        .background(isStreamMode ? Color.clear : Color(UIColor.systemGroupedBackground))
    }
}

// MARK: - Subviews & Helpers
extension HistoryCardDetail {
    
    private func headerLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .black))
            .foregroundColor(.secondary.opacity(0.6))
            .kerning(1.2)
    }

    private var meaningsList: some View {
        let meanings = word.meanings ?? []
        return VStack(alignment: .leading, spacing: 16) {
            ForEach(meanings.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: 12) {
                    Text("\(i + 1)")
                        .font(.system(size: 12, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color(red: 0.2, green: 0.4, blue: 0.2).opacity(0.6))
                        .clipShape(Circle())
                    
                    Text(meanings[i])
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }
    
    private var formattedDate: String {
        guard let date = status.lastModified else { return "Unknown" }
        let df = DateFormatter()
        df.dateStyle = .full
        return df.string(from: date)
    }
}
