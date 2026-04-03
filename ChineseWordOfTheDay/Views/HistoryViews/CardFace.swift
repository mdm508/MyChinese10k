//
//  CardFace.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 3/27/26.
//

import SwiftUI


/// A reusable shell that provides a consistent "Physical Card" look.
/// Handles background, borders, shadows, and clipping.
struct CardFace<Content: View>: View {
    let color: Color
    let content: Content
    
    /// The initializer uses @ViewBuilder so you can pass in VStacks/HStacks directly.
    init(color: Color = .clear, @ViewBuilder content: () -> Content) {
        self.color = color
        self.content = content()
    }
    
    var body: some View {
        ZStack {
            // 1. The main background color (System level)
            Color(uiColor: .secondarySystemGroupedBackground)
            
            // 2. The tinted overlay (The subtle blue/orange hint)
            color
            
            // 3. The actual text/icons
            content
        }
        // Ensure the card fills the square but stays clipped
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        // Subtle border to define the card against the background
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
        // Soft shadow for depth
        .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 2)
    }
}

// MARK: - Preview
struct CardFace_Previews: PreviewProvider {
    static var previews: some View {
        CardFace(color: .blue.opacity(0.1)) {
            Text("Preview")
        }
        .frame(width: 150, height: 150)
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

