//
//  WordOfTheDayWidget.swift
//  WordOfTheDayWidget
//
//  Created by m on 9/6/24.
//

import WidgetKit
import CoreDataModels
import Persistence
import SwiftUI

// Supplies the widget with timeline entries and handles updating the widget's content.
struct WordOfTheDayProvider: TimelineProvider {

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
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 30, to: currentDate)!
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }
}

// Represents a single entry in the widget's timeline, containing the data to display at a specific time.
struct WordEntry: TimelineEntry {
    let date: Date
    let word: WordRepresentable
}
extension WordEntry {
    var timeNowAsInt: Int {
        abs(Int(self.date.timeIntervalSince1970))
    }
    /// build the meanings array so we avoid long lines as a result of ";"
    /// instead split those lines and add them as possiblitly
    /// so hopefully we will end up with shorter lines
    var shortenedMeanings: [String] {
        var result: [String] = []
        for meaning in self.word.meanings {
            let pieces = meaning
                .split(separator: ";")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .map { $0.replacingOccurrences(of: #"\s*\([^)]*\)"#, with: "", options: .regularExpression) }
                .filter { !$0.isEmpty }
            result.append(contentsOf: pieces)
        }
        return result
    }
    // use the hour of the day to cycle through different meanings.
    // we allow no meaning ("") as a possiblity.
    var currentMeaning: String {
        let meanings = self.shortenedMeanings
        let meaningIndexNow = abs(timeNowAsInt) % meanings.count
        return meanings[meaningIndexNow]
    }
    // decide wether or not to show the pronunciation
    var beforeFourPM: Bool {
        let hour = Calendar.current.component(.hour, from: self.date)
        return hour < 16
    }
}

// Provides the visual representation of the widget's data.
struct WordOfTheDayWidgetEntryView : View {
    var entry: WordOfTheDayProvider.Entry
    var body: some View {
        VStack {
            GeometryReader { geo in
                // Calculate the font size based on the smallest dimension of the geometry reader's space
                let fontSize = min(geo.size.width, geo.size.height) * 0.70
                Text(entry.word.characters)
                    .font(.system(size: fontSize, weight: .bold, design: .default)) // Use custom size with dynamic adjustments
                    .lineLimit(1) // Ensure the text stays on one line
                    .minimumScaleFactor(0.3) // Allow text to scale down if needed to fit
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center) // Center the text
            }
            if entry.beforeFourPM {
                Text(entry.word.phonetic).font(.subheadline.bold()).lineLimit(1)
                Text(entry.currentMeaning).font(.footnote.italic()).lineLimit(2).minimumScaleFactor(0.5)
            }
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

