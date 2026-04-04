import SwiftUI
import CoreDataModels

struct HistoryCardDetail: View {
    // 🎯 CLEANER CONTRACT
    let status: WordStatus
    let word: Word
    var isStreamMode: Bool = false
    
    @Environment(\.managedObjectContext) var context
    @Environment(\.dismiss) var dismiss
    @StateObject private var speechVM = SpeechViewModel()

    var body: some View {
        if isStreamMode {
            detailContent
        } else {
                detailContent
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Done") { dismiss() }
                                .font(.system(size: 17, weight: .bold))
                                .foregroundColor(.forestGreen)
                        }
                    }
        }
    }

    private var detailContent: some View {
        ScrollView(showsIndicators: false) {
            // 🏗️ THE OUTER LAYER: This needs top padding so the ball isn't "cut" by the screen edge
            VStack(spacing: 0) {
                
                ZStack(alignment: .top) {
                    // 1. THE MAIN CARD
                    VStack(spacing: 0) {
                        
                        // --- 🍊 HERO SECTION (Orange Dream) ---
                        VStack(spacing: 0) {
                            Text(word.characters)
                                .font(.system(size: 110, weight: .bold, design: .serif))
                                .foregroundColor(speechVM.isSpeaking ? .blue : .terracotta)
                                .scaleEffect(speechVM.isSpeaking ? 1.05 : 1.0)
                                .padding(.top, 60) // Extra room for the pin
                                .onTapGesture {
                                    speechVM.speak(word.characters, .chineseTaiwan)
                                    UISelectionFeedbackGenerator().selectionChanged()
                                }
                            
                            VStack(spacing: 4) {
                                Text(word.phonetic)
                                    .font(.system(size: 26, weight: .bold, design: .rounded))
                                    .foregroundColor(.terracotta.opacity(0.7))
                            }
                            .padding(.bottom, 40)
                        }
                        .frame(maxWidth: .infinity)
                        .background(Color.orangeDream)
                        
                        // --- 🌿 DATA SECTION (Pastel Green) ---
                        VStack(alignment: .leading, spacing: 32) {
                            VStack(alignment: .leading, spacing: 12) {
                                headerLabel("Definitions")
                                meaningsList
                            }
                            
                            Divider().background(Color.forestGreen.opacity(0.1))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                headerLabel("Learned Date")
                                Text(formattedDate)
                                    .font(.system(size: 17, weight: .medium, design: .rounded))
                                    .foregroundColor(.forestGreen.opacity(0.8))
                            }
                        }
                        .padding(30)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.pastelGreen)
                    }
                    .cornerRadius(32) // The card's actual frame
                    .shadow(color: Color.black.opacity(0.06), radius: 20, x: 0, y: 10)
                    
                    // 2. THE POKÉBALL PIN (Floating on top of the frame)
                    Text("\(status.index)")
                        .font(.system(size: 11, weight: .black, design: .monospaced))
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                        .foregroundColor(.orangeDream)
                        .padding(.horizontal, 6)
                        .frame(width: 36, height: 36)
                        .background(
                            ZStack {
                                Circle() // The Sphere
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.terracotta.opacity(0.7), Color.terracotta.opacity(0.95)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                Circle() // The Glossy Rim
                                    .stroke(Color.white.opacity(0.4), lineWidth: 1.5)
                            }
                        )
                        .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 4)
                        // 🎯 MAGIC NUMBER: -18 pushes it exactly halfway over the top edge
                        .offset(y: -18)
                        .zIndex(99) // Ensures it's the highest thing in the universe
                }
                .padding(.horizontal, 20)
                .padding(.top, 40) // 🛡️ CRITICAL: This gives the ball "sky" so it doesn't clip
                .padding(.bottom, 30)
            }
        }
        .background(isStreamMode ? Color.clear : Color.pastelGreen.opacity(0.3))
    }
}

// MARK: - Subviews & Helpers
extension HistoryCardDetail {
    
    private func headerLabel(_ text: String) -> some View {
        Text(text.uppercased())
            .font(.system(size: 11, weight: .black))
            .foregroundColor(.forestGreen.opacity(0.4))
            .kerning(1.2)
    }

    private var meaningsList: some View {
        // Handle optionality safely
        let meanings = word.meanings ?? []
        
        return VStack(alignment: .leading, spacing: 16) {
            ForEach(meanings.indices, id: \.self) { i in
                HStack(alignment: .top, spacing: 12) {
                    // Circular Bullet
                    Text("\(i + 1)")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.forestGreen.opacity(0.5))
                        .clipShape(Circle())
                    
                    // Meaning Text
                    Text(meanings[i])
                        .font(.system(size: 19, weight: .medium, design: .rounded))
                        .foregroundColor(.forestGreen)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(4)
                }
            }
        }
    }
    
    // 📅 The Formatted Date helper
    private var formattedDate: String {
        guard let date = status.lastModified else { return "No Date Recorded" }
        let formatter = DateFormatter()
        formatter.dateStyle = .full // Friday, April 3, 2026
        return formatter.string(from: date)
    }
}
