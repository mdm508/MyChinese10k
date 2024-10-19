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
        con.widgetProcessHistory()
        let currentDate = Date()
        guard let currentWord = Word.fetchHigestPriorityUnseenWord(context: PersistenceController.shared.context) else {
            completion(Timeline(entries: [], policy: .never))
            return
        }
        let entry = WordEntry(date: currentDate, word: currentWord)
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
            Text("Time:")
            Text(entry.word.traditional)
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

