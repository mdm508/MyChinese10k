//
//  WordOfTheDayWidgetEntryView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 3/15/26.
//

import WidgetKit
import SwiftUI

struct WordOfTheDayWidgetEntryView: View {
    var entry: WordOfTheDayProvider.Entry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:
            SmallWordWidgetView(entry: entry)

        case .systemMedium:
            MediumWordWidgetView(entry: entry)

        case .accessoryInline:
            InlineWordWidgetView(entry: entry)

        case .accessoryCircular:
            CircularWordWidgetView(entry: entry)

        case .accessoryRectangular:
            RectangularWordWidgetView(entry: entry)

        default:
            SmallWordWidgetView(entry: entry)
        }
    }
}
struct WordOfTheDayWidgetEntryView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            preview(for: .systemSmall, name: "System Small")
            preview(for: .systemMedium, name: "System Medium")

            if #available(iOSApplicationExtension 16.0, *) {
                preview(for: .accessoryInline, name: "Accessory Inline")
                preview(for: .accessoryCircular, name: "Accessory Circular")
                preview(for: .accessoryRectangular, name: "Accessory Rectangular")
            }
        }
    }

    static func preview(for family: WidgetFamily, name: String) -> some View {
        let view = WordOfTheDayWidgetEntryView(entry: WidgetPreviewEntries.twoCharacters)
            .previewContext(WidgetPreviewContext(family: family))
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
