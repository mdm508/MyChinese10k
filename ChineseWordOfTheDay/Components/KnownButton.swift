//
//  BigGreenButton.swift
//  ChineseWordOfTheDay
//
//  Created by m on 2/2/24.
//

import SwiftUI


struct BigGreenButton: View {
    let parentSize: CGSize
    let action: () -> Void
    @State private var isPressed = false
}
extension BigGreenButton{
    var body: some View {
        Button(action: {
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            self.action()
        }, label: {
            ZStack {
                Circle()
                    .foregroundStyle(Color.mint)
                    .frame(width: self.buttonSize, height: self.buttonSize)
                    .shadow(color: .black.opacity(isPressed ? 0.4 : 0.2),
                            radius: self.isPressed ? 0 : 7,
                            x: 0,
                            y: 0
                            )
                    .overlay(
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.9),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: self.buttonSize, height: self.buttonSize)
                    )
                    .overlay(
                        Circle()
                            .stroke(Color.clear, lineWidth: 1.5)
                    )
                Text("知道了")
                    .font(.system(size: self.buttonSize * 0.23, weight: .light))
                    .foregroundColor(.white)
            }
        })
        .buttonStyle(ScaleButtonStyle())
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    withAnimation(.linear(duration: 0.03)) { isPressed = true }
                }
                .onEnded { _ in
                    withAnimation(.linear(duration: 0.06)) { isPressed = false }
                }
        )
    }
}
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}
extension BigGreenButton {
    static let percentageOfScreen: CGFloat = 20/100 
    static let paddingAmount = 0.15
    var dynamicPadding: CGFloat {
        return self.buttonSize * Self.paddingAmount
    }
    var buttonSize: CGFloat {
        return min(self.parentSize.width, self.parentSize.height) * Self.percentageOfScreen
    }
}
