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
            self.action()
        }, label: {
            Image(systemName: "checkmark")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                
                .padding(dynamicPadding)
                .frame(width: self.buttonSize, height: self.buttonSize, alignment: .center)
                .background(Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.green, Color.green.opacity(0.7)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .overlay(
                        Circle()
                            .stroke(Color.white, lineWidth: 2) // Border around the button
                    ))
        })
        .shadow(color: .gray, radius: 4, x: -2, y: -1) // Add a drop shadow
        .padding()
        
    }
}
extension BigGreenButton {
    static let percentageOfScreen: CGFloat = 16/100
    static let paddingAmount = 0.15
    var dynamicPadding: CGFloat {
        return self.buttonSize * Self.paddingAmount
    }
    var buttonSize: CGFloat {
        return min(self.parentSize.width, self.parentSize.height) * Self.percentageOfScreen
    }
}
