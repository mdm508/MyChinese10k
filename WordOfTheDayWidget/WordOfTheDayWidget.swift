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



struct WordOfTheDayProvider: TimelineProvider {
    static let refreshFreqMinutes = 1
    func placeholder(in context: Context) -> WordEntry {
        return WordEntry(date: Date(), word: MockWord.placeholder, selectedMeaning: MockWord.placeholder.meanings[0])
    }
    // Provides a snapshot of the widget's content for quick previews, such as when adding the widget.
    func getSnapshot(in context: Context, completion: @escaping (WordEntry) -> ()) {
        let entry = WordEntry(date: Date(),
                              word: MockWord.placeholder,
                              selectedMeaning: MockWord.placeholder.meanings[0])
        completion(entry)
    }
    func getTimeline(in context: Context, completion: @escaping (Timeline<WordEntry>) -> Void) {
        let now = Date()
        let word = MockWord.readFromUserDefaults() ?? MockWord.placeholder
        let meanings = word.cleanedMeanings()
        guard !meanings.isEmpty else {
            let entry = WordEntry(date: now, word: word, selectedMeaning: nil)
            completion(Timeline(entries: [entry], policy: .never))
            return
        }
        var entries: [WordEntry] = []
        for step in 0..<12 {
            let meaning:String?
            if step != 0 && step % 3 == 0 {
                meaning = nil
            } else {
                meaning = meanings[step % meanings.count]
            }
//            let entryDate = Calendar.current.date(byAdding: .minute,
//                                                  value: step * Self.refreshFreqMinutes,
//                                                  to: now)!
            let entryDate = now.addingTimeInterval(Double(step) * 5.0)
            let entry = WordEntry(date: entryDate, word: word, selectedMeaning: meaning)
            entries.append(entry)
        }
        completion(Timeline(entries: entries, policy: .atEnd))
    }

}

@main
struct WordOfTheDayWidget: Widget {
    let kind: String = "WordOfTheDayWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WordOfTheDayProvider()) { entry in
            if #available(iOS 17.0, *) {
                WordOfTheDayWidgetEntryView(entry: entry)
                    .containerBackground(for: .widget) {
                        Color.clear
                    }
            } else {
                WordOfTheDayWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("Waabl Widget")
        .description("Display the current word of the day.")
        .supportedFamilies(supportedFamilies)
    }

    private var supportedFamilies: [WidgetFamily] {
        if #available(iOSApplicationExtension 16.0, *) {
            return [
                .systemSmall,
                .systemMedium,
                .accessoryInline,
                .accessoryCircular,
                .accessoryRectangular
            ]
        } else {
            return [
                .systemSmall,
                .systemMedium
            ]
        }
    }
}


