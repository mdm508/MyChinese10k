//
//  RectangularWordWidgetView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 3/15/26.
//


import SwiftUI
import WidgetKit

struct RectangularWordWidgetView: View {
    let entry: WordEntry

    var body: some View {
        HStack(spacing: 8) {
            Text(entry.word.characters)
                .font(.system(size: 22, weight: .bold, design: .default))
                .lineLimit(1)
                .minimumScaleFactor(0.5)

            VStack(alignment: .leading, spacing: 2) {
                Text(entry.word.phonetic)
                    .font(.caption2)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if let meaning = entry.selectedMeaning, !meaning.isEmpty {
                    Text(meaning)
                        .font(.caption2)
                        .lineLimit(2)
                        .minimumScaleFactor(0.5)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct RectangularWordWidgetView_Previews: PreviewProvider {
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
        let view = RectangularWordWidgetView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .accessoryRectangular))
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
