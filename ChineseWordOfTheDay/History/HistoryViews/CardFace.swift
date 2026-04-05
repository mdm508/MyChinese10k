//
//  CardFace.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 3/27/26.
//

import SwiftUI


/// A reusable shell that provides a consistent "Physical Card" look.
struct CardFace<Content: View>: View {
    let color: Color
    let content: Content
    init(color: Color = .clear, @ViewBuilder content: () -> Content) {
        self.color = color
        self.content = content()
    }
    var body: some View {
        ZStack {
            Color(uiColor: .secondarySystemGroupedBackground)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
        )
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

