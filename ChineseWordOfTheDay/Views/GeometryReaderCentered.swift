//
//  GeometryReaderCentered.swift
//  ChineseWordOfTheDay
//
//  Created by m on 6/16/23.
//

import SwiftUI

struct GeometryReaderCentered<Content: View>: View {
    var content: (GeometryProxy) -> Content

    var body: some View {
        GeometryReader { geometry in
            Group {
                content(geometry)
            }
            .frame(
                width: geometry.size.width,
                height: geometry.size.height,
                alignment: .center
            )
        }
    }
}
