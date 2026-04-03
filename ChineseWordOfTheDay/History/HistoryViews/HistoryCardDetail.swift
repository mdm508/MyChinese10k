//
//  HistoryCardDetail.swift
//  ChineseWordOfTheDay
//
//  Created by m on 4/2/26.
//


import SwiftUI

struct HistoryCardDetail: View {
    let card: CardData
    @Environment(\.dismiss) var dismiss
    
    // Inject Speech Engine
    @StateObject private var speechVM = SpeechViewModel()

    var body: some View {
        NavigationView {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 32) {
                    
                    // --- 🐲 THE HERO INTERACTION ---
                    // No buttons. No icons. Just the character.
                    VStack(spacing: 16) {
                        Text(card.characters)
                            .font(.system(size: 110, weight: .bold, design: .serif))
                            .foregroundColor(speechVM.isSpeaking ? .blue : .primary)
                            // The "Breath" Animation: Scales up and glows when speaking
                            .scaleEffect(speechVM.isSpeaking ? 1.08 : 1.0)
                            .shadow(color: speechVM.isSpeaking ? .blue.opacity(0.25) : .clear, radius: 15)
                            .onTapGesture {
                                speechVM.speak(card.characters, .chineseTaiwan)
                                UISelectionFeedbackGenerator().selectionChanged()
                            }
                        
                        VStack(spacing: 4) {
                            Text(card.phonetic)
                                .font(.system(size: 24, weight: .bold, design: .rounded))
                                .foregroundColor(.primary)
                            
                            if speechVM.isSpeaking {
                                Text("Speaking...")
                                    .font(.system(size: 12, weight: .black))
                                    .foregroundColor(.blue)
                                    .transition(.opacity)
                            }
                        }
                    }
                    .padding(.top, 50)
                    .padding(.bottom, 20)
                    .animation(.spring(response: 0.3, dampingFraction: 0.6), value: speechVM.isSpeaking)

                    // --- 📝 DATA CARD ---
                    VStack(alignment: .leading, spacing: 28) {
                        // Meanings Section
                        detailRow(title: "Meanings", content: meaningsList)
                        
                        Divider().opacity(0.5)
                        
                        // Metadata Grid
                        HStack(alignment: .top) {
                            detailRow(title: "Index", content: Text("#\(card.wordIndex)"))
                            Spacer()
                            detailRow(title: "Learned", content: Text(formattedDate))
                        }
                    }
                    .padding(28)
                    .background(Color(UIColor.secondarySystemGroupedBackground))
                    .cornerRadius(28)
                    .shadow(color: Color.black.opacity(0.03), radius: 10, x: 0, y: 5)
                }
                .padding(.horizontal)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .font(.system(size: 17, weight: .bold))
                }
            }
        }
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
                .kerning(1.2) // Tight professional letter spacing
            content
        }
    }
}