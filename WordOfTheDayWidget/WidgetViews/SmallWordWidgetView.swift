//
//  SmallWordWidgetView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 3/15/26.
//


import SwiftUI
import WidgetKit
import CoreDataModels

struct SmallWordWidgetView: View {
    let entry: WordEntry

    var body: some View {
        VStack(spacing: 2) {
            ResizingCharacterText(characters: entry.word.characters)

            if let currentMeaning = entry.selectedMeaning {
                Text(entry.word.phonetic)
                    .font(.footnote.italic())
                    .lineLimit(1)
                    .minimumScaleFactor(0.45)

                Text(currentMeaning)
                    .font(.footnote.italic())
                    .lineLimit(2)
                    .minimumScaleFactor(0.45)
            }
        }
    }
}

struct SmallWordWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(WidgetPreviewEntries.allSmall.indices, id: \.self) { index in
                let preview = WidgetPreviewEntries.allSmall[index]

                if #available(iOS 17.0, *) {
                    SmallWordWidgetView(entry: preview.entry)
                        .containerBackground(for: .widget) {
                            Color.clear
                        }
                        .previewContext(WidgetPreviewContext(family: .systemSmall))
                        .previewDisplayName(preview.name)
                } else {
                    SmallWordWidgetView(entry: preview.entry)
                        .previewContext(WidgetPreviewContext(family: .systemSmall))
                        .previewDisplayName(preview.name)
                }
            }
        }
    }
}
