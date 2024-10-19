//
//  WordOfTheDayWidget.swift
//  WordOfTheDayWidget
//
//  Created by m on 9/6/24.
//

import WidgetKit
import SwiftUI

// Supplies the widget with timeline entries and handles updating the widget's content.
struct WordOfTheDayProvider: TimelineProvider {
    var con = PersistenceController.shared

    // Provides a placeholder view displayed in the widget gallery before the actual data is available.
    func placeholder(in context: Context) -> WordEntry {
        return WordEntry(date: Date(), word: MockWord.placeholder)
    }
    // Provides a snapshot of the widget's content for quick previews, such as when adding the widget.
    func getSnapshot(in context: Context, completion: @escaping (WordEntry) -> ()) {
        let entry = WordEntry(date: Date(), word: MockWord.placeholder)
        completion(entry)
    }

    // Generates the timeline of entries that dictate the widget's content over time.
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        let currentDate = Date()
        let entry: WordEntry
        if let currentWord = MockWord.readFromUserDefaults(){
            entry = WordEntry(date: currentDate, word: currentWord)
        } else {
            entry = WordEntry(date: currentDate, word: MockWord.placeholder)
        }
        let timeline = Timeline(entries: [entry], policy: .never)
        completion(timeline)
    }
}

// Represents a single entry in the widget's timeline, containing the data to display at a specific time.
struct WordEntry: TimelineEntry {
    let date: Date
    let word: WordRepresentable
}

// Provides the visual representation of the widget's data.
struct WordOfTheDayWidgetEntryView : View {
    var entry: WordOfTheDayProvider.Entry
    var body: some View {
        VStack {
            Text("\(entry.date.formatted(date: .abbreviated, time: .omitted))").font(.footnote).fontWeight(Font.Weight.light)
            GeometryReader { geo in
                // Calculate the font size based on the smallest dimension of the geometry reader's space
                let fontSize = min(geo.size.width, geo.size.height) * 0.85
                Text(entry.word.traditional)
                    .font(.system(size: fontSize, weight: .bold, design: .default)) // Use custom size with dynamic adjustments
                    .lineLimit(1) // Ensure the text stays on one line
                    .minimumScaleFactor(0.5) // Allow text to scale down if needed to fit
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // Center the text
            }

            Text(entry.word.zhuyin).font(.subheadline)
        }
    }
}

@main
struct WordOfTheDayWidget: Widget {
    let kind: String = "WordOfTheDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WordOfTheDayProvider()) { entry in
            if #available(iOS 17.0, *) {
                WordOfTheDayWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                WordOfTheDayWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Waabl Widget")
        .description("Display the current word of the day")
    }
}

