//
//  InlineWordWidgetView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 3/15/26.
//


import SwiftUI
import WidgetKit

struct InlineWordWidgetView: View {
    let entry: WordEntry

    var body: some View {
        Text(entry.word.characters)
            .lineLimit(1)
    }
}

struct InlineWordWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            if #available(iOSApplicationExtension 16.0, *) {
                ForEach(WidgetPreviewEntries.allSmall.indices, id: \.self) { index in
                    let previewCase = WidgetPreviewEntries.allSmall[index]
                    preview(entry: previewCase.entry, name: previewCase.name)
                }
            }
        }
    }

    @available(iOSApplicationExtension 16.0, *)
    static func preview(entry: WordEntry, name: String) -> some View {
        let view = InlineWordWidgetView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .accessoryInline))
            .previewDisplayName(name)

        if #available(iOS 17.0, *) {
            return AnyView(
                view.containerBackground(for: .widget) {
                    Color.clear
                }
            )
        } else {
            return AnyView(view)
        }
    }
}
