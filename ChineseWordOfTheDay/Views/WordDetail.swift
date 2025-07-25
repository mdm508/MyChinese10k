//
//  WordDetailView.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 6/9/25.
//

import SwiftUI
import CoreDataModels

/// A view that displays a single word's details and provides a callback to load the next word.
struct WordDetail {
    // MARK: - Properties
    /// The word to display (traditional characters, zhuyin, and meanings).
    @Binding var word: WordRepresentable
    /// Async callback triggered when the user taps the Next button.
    let onNext: @MainActor () async -> Void
    /// Phonetic description of `hanzi` in either zhuyin or pinyin.
    @State private var phonetic: String = ""
    /// Chinese character in simplified or traditional.
    @State private var hanzi: String = ""
}

// MARK: - Loading User Settings
extension WordDetail {
    func loadPhonetic() async {
        if await UserPreferences.get(.phoneticNotation) == .zhuyin {
            self.phonetic = self.word.zhuyin
        }
        else {
            self.phonetic = self.word.pinyin
        }
    }
    func loadHanzi() async {
        if await UserPreferences.get(.chineseWritingSystem) == .traditional {
            self.hanzi = self.word.traditional
        }
        else {
            self.hanzi = self.word.simplified
        }
    }
}

// MARK: - View Conformance
extension WordDetail: View {
    var body: some View {
        GeometryReaderCentered { geo in
            content(in: geo)
        }.task{
            // load properties
            await loadPhonetic()
            await loadHanzi()
        }
    }
}

// MARK: - Layout & Subviews

private extension WordDetail {
    /// The main content layout inside the GeometryReader.
    func content(in geo: GeometryProxy) -> some View {
        VStack(alignment: .center) {
            WordView(word: self.$hanzi, size: geo.size)
            Text(self.phonetic)
                .font(.headline)

            meaningsList

            nextButton(in: geo)
                .background(Color.clear)
        }
        .padding()
    }

    /// A scrollable list of the word's meanings.
    var meaningsList: some View {
        List(word.meanings, id: \.self) { meaning in
            Text(meaning)
        }
        .listStyle(.plain)
    }

    /// The Next button aligned to the bottom trailing corner.
    func nextButton(in geo: GeometryProxy) -> some View {
        HStack {
            Spacer()
            BigGreenButton(parentSize: geo.size) {
                Task {
                    await onNext()
                    await self.loadHanzi()
                    await self.loadPhonetic()
                }
            }
        }
    }
}

// MARK: - Preview

//struct WordDetail_Previews: PreviewProvider {
//    static var previews: some View {
//        WordDetail(
//            word: MockWord.placeholder,
//            onNext: { }
//        )
//    }
//}
