//
//  ExampleSentencesDebugView.swift
//  ExampleSentences
//

import SwiftUI

/// A screen for checking generated example sentences by eye.
///
/// Pick a word, tap Generate, and each sense fills in as the model finishes it.
/// A green check means the sense check agreed a sentence uses that sense, an orange
/// question mark means the word is used but the check read another meaning, and
/// sentences missing the word are shown in red. Free mode instead asks for four
/// sentences in one call and lets the model choose the meanings.
public struct ExampleSentencesDebugView: View {
    private let words: [TargetWord]
    private let generator: ExampleSentenceGenerator

    @State private var selectedIndex: Int64?
    @State private var results: [SenseExamples] = []
    @State private var freeMode = false
    @State private var freeResult: FreeExamples?
    @State private var isGenerating = false
    @State private var elapsed: Duration?

    public init(words: [TargetWord], generator: ExampleSentenceGenerator = ExampleSentenceGenerator()) {
        self.words = words
        self.generator = generator
        _selectedIndex = State(initialValue: words.first?.index)
    }

    private var selectedWord: TargetWord? {
        words.first { $0.index == selectedIndex }
    }

    public var body: some View {
        List {
            modelSection
            wordSection
            if let word = selectedWord {
                if freeMode {
                    freeSection(of: word)
                } else {
                    ForEach(word.senses) { sense in
                        senseSection(sense, of: word)
                    }
                }
                if !word.notes.isEmpty {
                    Section("Skipped dictionary notes") {
                        ForEach(word.notes, id: \.self) { Text($0).foregroundStyle(.secondary) }
                    }
                }
            }
        }
        .navigationTitle("AI Example Sentences")
        .onChange(of: selectedIndex) { clearResults() }
        .onChange(of: freeMode) { clearResults() }
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
        }
    }

    private var wordSection: some View {
        Section("Word") {
            Picker("Word", selection: $selectedIndex) {
                ForEach(words) { word in
                    Text("\(word.characters)  \(word.pinyin)").tag(Optional(word.index))
                }
            }
            Picker("Mode", selection: $freeMode) {
                Text("Every sense").tag(false)
                Text("Free").tag(true)
            }
            .pickerStyle(.segmented)
            .disabled(isGenerating)
            if let word = selectedWord {
                Text("\(word.senses.count) senses · \(word.script.displayName)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
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
                if !isGenerating {
                    if freeMode, let freeResult {
                        freeSummary(freeResult)
                    } else if !freeMode, !results.isEmpty {
                        summary(for: word)
                    }
                }
            }
        }
    }

    private var elapsedText: String {
        elapsed.map { " in " + $0.formatted(.units(allowed: [.seconds], fractionalPart: .show(length: 1))) } ?? ""
    }

    private func freeSummary(_ result: FreeExamples) -> some View {
        let used = result.sensesUsed.map(String.init).joined(separator: ", ")
        return Label(
            "\(result.sentences.count) sentences, meanings used: \(used.isEmpty ? "none" : used)\(elapsedText)",
            systemImage: "text.bubble"
        )
    }

    private func freeSection(of word: TargetWord) -> some View {
        Section("Sentences") {
            if let freeResult {
                if let failure = freeResult.failure {
                    Text(failure).foregroundStyle(.red)
                }
                ForEach(freeResult.sentences) { sentence in
                    VStack(alignment: .leading, spacing: 4) {
                        sentenceRow(sentence, sense: nil, word: word)
                        let meaning = word.senses.first { $0.number == sentence.judgedSense }
                        Text(meaning.map { "Meaning \($0.number). \($0.definition)" } ?? "Meaning not given")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            } else if isGenerating {
                Text("Waiting…").foregroundStyle(.secondary)
            }
        }
    }

    private func summary(for word: TargetWord) -> some View {
        let covered = results.filter(\.isCovered).count
        let verified = results.filter(\.isVerified).count
        let allCovered = covered == word.senses.count
        let seconds = elapsedText
        return Label(
            "\(covered)/\(word.senses.count) senses covered, \(verified) passed the sense check\(seconds)",
            systemImage: allCovered ? "checkmark.seal.fill" : "xmark.seal.fill"
        )
        .foregroundStyle(allCovered ? .green : .red)
    }

    private func senseSection(_ sense: WordSense, of word: TargetWord) -> some View {
        let examples = results.first { $0.sense == sense }
        return Section {
            if let examples {
                if let failure = examples.failure, examples.sentences.isEmpty {
                    Text(failure).foregroundStyle(.red)
                }
                ForEach(examples.sentences) { sentence in
                    sentenceRow(sentence, sense: sense, word: word)
                }
                Text("\(examples.attempts) model call\(examples.attempts == 1 ? "" : "s")")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else if isGenerating {
                Text("Waiting…").foregroundStyle(.secondary)
            }
        } header: {
            HStack(alignment: .firstTextBaseline) {
                if let examples {
                    Image(systemName: examples.isVerified ? "checkmark.circle.fill"
                          : examples.isCovered ? "questionmark.circle.fill" : "xmark.circle.fill")
                        .foregroundStyle(examples.isVerified ? .green : examples.isCovered ? .orange : .red)
                }
                Text("\(sense.number). \(sense.definition)")
                    .textCase(nil)
            }
        }
    }

    private func sentenceRow(_ sentence: ExampleSentence, sense: WordSense?, word: TargetWord) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(highlighted(sentence.chinese, word: word))
                .font(.title3)
            Text(sentence.english)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if !sentence.containsTarget {
                Text("Doesn't contain \(word.characters)")
                    .font(.caption)
                    .foregroundStyle(.red)
            } else if let sense, let judged = sentence.judgedSense, judged != sense.number {
                Text("Sense check reads this as meaning \(judged)")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
        }
        .textSelection(.enabled)
        .padding(.vertical, 2)
    }

    private func highlighted(_ chinese: String, word: TargetWord) -> AttributedString {
        var text = AttributedString(chinese)
        for form in Set([word.characters, word.simplified, word.traditional]) {
            if let range = text.range(of: form) {
                text[range].foregroundColor = .accentColor
                text[range].font = .title3.bold()
            }
        }
        return text
    }

    // MARK: Generation

    private func clearResults() {
        results = []
        freeResult = nil
        elapsed = nil
    }

    private func generate(for word: TargetWord) async {
        isGenerating = true
        clearResults()
        let clock = ContinuousClock()
        let start = clock.now
        if freeMode {
            let result = await generator.freeExamples(for: word)
            if selectedIndex == word.index, freeMode {
                freeResult = result
            }
            elapsed = clock.now - start
            isGenerating = false
            return
        }
        for sense in word.senses {
            let examples = await generator.examples(for: sense, of: word)
            // Drop the result if the user picked another word meanwhile.
            guard selectedIndex == word.index else { break }
            results.append(examples)
        }
        elapsed = clock.now - start
        isGenerating = false
    }
}

#Preview {
    NavigationStack {
        ExampleSentencesDebugView(words: [
            TargetWord(
                index: 1,
                simplified: "学习",
                traditional: "學習",
                pinyin: "xuéxí",
                meanings: ["to learn; to study", "to emulate"],
                script: .traditional
            )
        ])
    }
}
