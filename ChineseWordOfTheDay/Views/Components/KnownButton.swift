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
}
extension BigGreenButton{
    var body: some View {
        Button(action: {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
            impactFeedback.impactOccurred()
            
            self.action()
        }, label: {
            // Inner circle with depth effect
            ZStack {
                // Outer shadow circle for depth
                Circle()
                    .fill(Color.black.opacity(0.2))
                    .frame(width: self.buttonSize + 8, height: self.buttonSize + 8)
                    .offset(y: 4)
                
                // Main button circle
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [
                            Color.green.opacity(0.9),
                            Color.green,
                            Color.green.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: self.buttonSize, height: self.buttonSize)
                    .overlay(
                        // Inner highlight for 3D effect
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.3),
                                    Color.clear
                                ]),
                                startPoint: .topLeading,
                                endPoint: .center
                            ))
                            .frame(width: self.buttonSize * 0.7, height: self.buttonSize * 0.7)
                            .offset(x: -self.buttonSize * 0.15, y: -self.buttonSize * 0.15)
                    )
                    .overlay(
                        // Border for definition
                        Circle()
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.4), radius: 12, x: 0, y: 6)
                
                // Chinese text in the center
                Text("知道")
                    .font(.system(size: self.buttonSize * 0.25, weight: .medium))
                    .foregroundColor(.white)
            }
        })
        .buttonStyle(ScaleButtonStyle())
    }
}

// Custom button style for better button feel
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .offset(y: configuration.isPressed ? 2 : 0)
            .animation(.easeInOut(duration: 0.08), value: configuration.isPressed)
    }
}
extension BigGreenButton {
    static let percentageOfScreen: CGFloat = 25/100 // Increased from 16/100
    static let paddingAmount = 0.15
    var dynamicPadding: CGFloat {
        return self.buttonSize * Self.paddingAmount
    }
    var buttonSize: CGFloat {
        return min(self.parentSize.width, self.parentSize.height) * Self.percentageOfScreen
    }
}
