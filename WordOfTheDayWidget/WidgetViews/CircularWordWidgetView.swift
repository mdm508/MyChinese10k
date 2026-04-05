//
//  CircularWordWidgetView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 3/15/26.
//


import SwiftUI
import WidgetKit

struct CircularWordWidgetView: View {
    let entry: WordEntry
    var body: some View {
        Text(entry.word.characters)
            .font(.system(size: fontSizeForCharacterCount(), weight: .bold))
            .lineLimit(2)
            .minimumScaleFactor(0.4)
            .multilineTextAlignment(.center)
    }
    private func fontSizeForCharacterCount() -> CGFloat {
        let count = max(entry.word.characters.count, 1)
        switch count {
        case 1: return 22
        case 2: return 18
        case 3: return 15
        default: return 13
        }
    }
}
struct CircularWordWidgetView_Previews: PreviewProvider {
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
        let view = CircularWordWidgetView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .accessoryCircular))
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
