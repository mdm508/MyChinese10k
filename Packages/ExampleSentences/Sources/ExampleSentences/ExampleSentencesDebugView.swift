//
//  ExampleSentencesDebugView.swift
//  ExampleSentences
//

import SwiftUI

/// A screen for checking generated example sentences by eye.
///
/// Pick a word and tap Generate. Each sentence shows its words with pinyin
/// above and zhuyin below (words found in the dictionary are underlined),
/// then the simplified sentence and the English.
public struct ExampleSentencesDebugView: View {
    private let words: [TargetWord]
    private let generator: ExampleSentenceGenerator
    private let loadDictionary: (@MainActor () -> ReadingDictionary)?

    @State private var selectedIndex: Int64?
    @State private var result: ExampleSentenceResult?
    @State private var isGenerating = false
    @State private var elapsed: Duration?
    @State private var dictionary: ReadingDictionary?

    /// - Parameter loadDictionary: Builds the readings dictionary, for example
    ///   from the app's word list. Called once, the first time the screen appears.
    public init(
        words: [TargetWord],
        generator: ExampleSentenceGenerator = ExampleSentenceGenerator(),
        loadDictionary: (@MainActor () -> ReadingDictionary)? = nil
    ) {
        self.words = words
        self.generator = generator
        self.loadDictionary = loadDictionary
        _selectedIndex = State(initialValue: words.first?.index)
    }

    private var selectedWord: TargetWord? {
        words.first { $0.index == selectedIndex }
    }

    public var body: some View {
        List {
            modelSection
            wordSection
            if let word = selectedWord, let result, result.word == word {
                Section("Sentences") {
                    if let failure = result.failure {
                        Text(failure).foregroundStyle(.red)
                    }
                    ForEach(result.sentences) { sentence in
                        sentenceRow(sentence, word: word)
                    }
                }
            }
        }
        .navigationTitle("AI Example Sentences")
        .task {
            if dictionary == nil, let loadDictionary {
                dictionary = loadDictionary()
            }
        }
        .onChange(of: selectedIndex) {
            result = nil
            elapsed = nil
        }
    }

    // MARK: Sections

    private var modelSection: some View {
        Section("Model") {
            if let reason = ExampleSentenceGenerator.unavailableReason {
                Label(reason, systemImage: "exclamationmark.triangle.fill")
                    .foregroundStyle(.orange)
            } else {
                Label("On-device model ready", systemImage: "apple.intelligence")
            }
            Text("Reading dictionary: \((dictionary ?? generator.dictionary).count) words")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private var wordSection: some View {
        Section("Word") {
            Picker("Word", selection: $selectedIndex) {
                ForEach(words) { word in
                    Text("\(word.traditional)  \(word.pinyin)").tag(Optional(word.index))
                }
            }
            if let word = selectedWord {
                Button {
                    Task { await generate(for: word) }
                } label: {
                    HStack {
                        Text(isGenerating ? "Generating…" : "Generate")
                        if isGenerating {
                            Spacer()
                            ProgressView()
                        }
                    }
                }
                .disabled(isGenerating || !ExampleSentenceGenerator.isModelAvailable)
                if let result, !isGenerating {
                    Text("\(result.sentences.count) sentences, \(result.attempts) model call\(result.attempts == 1 ? "" : "s")\(elapsedText)")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var elapsedText: String {
        elapsed.map { " in " + $0.formatted(.units(allowed: [.seconds], fractionalPart: .show(length: 1))) } ?? ""
    }

    private func sentenceRow(_ sentence: ExampleSentence, word: TargetWord) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .top, spacing: 6) {
                    ForEach(sentence.traditional.indices, id: \.self) { i in
                        VStack(spacing: 2) {
                            Text(sentence.pinyin[i]).font(.caption2).foregroundStyle(.secondary)
                            Text(sentence.traditional[i])
                                .font(.title2)
                                .underline(sentence.dictionaryIndices[i] != nil)
                            Text(sentence.zhuyin[i]).font(.caption2).foregroundStyle(.secondary)
                        }
                        .fixedSize()
                    }
                }
            }
            Text(highlighted(sentence.traditionalText, word: word.traditional))
            Text(highlighted(sentence.simplifiedText, word: word.simplified))
                .foregroundStyle(.secondary)
            Text(sentence.english)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .textSelection(.enabled)
        .padding(.vertical, 4)
    }

    private func highlighted(_ text: String, word: String) -> AttributedString {
        var attributed = AttributedString(text)
        if let range = attributed.range(of: word) {
            attributed[range].foregroundColor = .accentColor
            attributed[range].font = .body.bold()
        }
        return attributed
    }

    // MARK: Generation

    private func generate(for word: TargetWord) async {
        isGenerating = true
        result = nil
        elapsed = nil
        let clock = ContinuousClock()
        let start = clock.now
        var generator = generator
        if let dictionary {
            generator.dictionary = dictionary
        }
        let generated = await generator.generate(for: word)
        // Drop the result if the user picked another word meanwhile.
        if selectedIndex == word.index {
            result = generated
            elapsed = clock.now - start
        }
        isGenerating = false
    }
}

#Preview {
    NavigationStack {
        ExampleSentencesDebugView(words: TargetWord.samples)
    }
}
