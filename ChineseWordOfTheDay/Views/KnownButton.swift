//
//  BigGreenButton.swift
//  ChineseWordOfTheDay
//
//  Created by m on 2/2/24.
//

import SwiftUI


struct BigGreenButton: View {
    let size: CGSize
    let action: () -> Void
}
extension BigGreenButton{
    var body: some View {
        Button(action: {
            self.action()
        }, label: {
            Image(systemName: "k")
                .resizable()
                .scaledToFit()
                .foregroundStyle(.white)
                .padding(EdgeInsets(top: dynamicPadding, leading: dynamicPadding, bottom: dynamicPadding, trailing: dynamicPadding))
                .frame(width: self.buttonWidth, height: self.buttonHeight, alignment: .center)
                .background(Circle()
                    .fill(Color.green))
        })
        .shadow(color: .gray, radius: 4, x: -2, y: -1) // Add a drop shadow
        .padding()
        
    }
}
extension BigGreenButton {
    static let percentage: CGFloat = 20/100
    static let paddingAmount = 0.2
    var dynamicPadding: CGFloat {
        return min(self.buttonHeight, self.buttonWidth) * Self.paddingAmount
    }
    var buttonWidth: CGFloat {
        return self.size.width * Self.percentage
    }
    var buttonHeight: CGFloat {
        return self.size.width * Self.percentage
    }
}
