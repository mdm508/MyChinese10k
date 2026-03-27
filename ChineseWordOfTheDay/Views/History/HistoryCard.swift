//
//  HistoryCard.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 3/27/26.
//


import SwiftUI

/// `HistoryCard` coordinates the 3D flip interaction.
/// It takes `CardData` as an input and maintains its own
/// internal @State for the "flipped" orientation.
struct HistoryCard: View {
    let card: CardData
    @State private var isFlipped: Bool = false
    
    var body: some View {
        ZStack {
            // FRONT: The "Character" Side
            frontSide
                .opacity(isFlipped ? 0 : 1)
            
            // BACK: The "Meaning" Side
            backSide
                .opacity(isFlipped ? 1 : 0)
                .rotation3DEffect(.degrees(180), axis: (x: 0, y: 1, z: 0))
        }
        .aspectRatio(1, contentMode: .fit)
        .rotation3DEffect(.degrees(isFlipped ? 180 : 0), axis: (x: 0, y: 1, z: 0))
        .onTapGesture {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.6)) {
                isFlipped.toggle()
            }
        }
    }
    
    // MARK: - Subviews
    
    private var frontSide: some View {
        CardFace(color: .blue.opacity(0.1)) {
            VStack(spacing: 0) {
                // Our new Specialist View handles the padding and scaling
                HistoryWordView(text: card.characters)
                
                // Secondary info stays small at the bottom
                Text(card.phonetic)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 12) // Matches the 12pt internal padding
            }
        }
    }
    
    private var backSide: some View {
        CardFace(color: .orange.opacity(0.1)) {
            VStack(spacing: 8) {
                Text(card.displayMeaning)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Mastery Badge
                Text("Level \(card.status)")
                    .font(.system(size: 10, weight: .black))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(4)
            }
            .padding(12) // Consistent padding across both sides
        }
    }
}
