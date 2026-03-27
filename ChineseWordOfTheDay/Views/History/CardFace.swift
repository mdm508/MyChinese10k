//
//  CardFace.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 3/27/26.
//

import SwiftUI

/// `CardFace` is a layout primitive.
/// It handles the "Physical" attributes: shadows, borders, and background.
/// It uses a `@ViewBuilder` closure to allow any content to be injected.
struct CardFace<Content: View>: View {
    let color: Color
    @ViewBuilder let content: () -> Content
    
    var body: some View {
        RoundedRectangle(cornerRadius: 16, style: .continuous)
            .fill(color)
            .overlay(
                // A subtle stroke provides depth and separation in Dark Mode
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(Color.primary.opacity(0.1), lineWidth: 1)
            )
            .overlay(content())
            .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}

/// A standardized header for our sections.
/// We use `.ultraThinMaterial` to give a "glass" effect that
/// blurs the cards beneath it as they scroll under the pinned header.
struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(8)
            .padding(.horizontal)
            .background(.ultraThinMaterial)
    }
}
