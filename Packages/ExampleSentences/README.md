# ExampleSentences

Generates Chinese example sentences for a word with Apple's on-device
Foundation Models framework (iOS 26 / macOS 26, Apple Intelligence on).

Input is any `WordRepresentable` (the Core Data `Word` or a `MockWord`),
wrapped in a `TargetWord`. Output is an `ExampleSentenceResult` holding
`ExampleSentence`s. Each sentence is split into words, and these arrays have one
entry per word, in order:

- `traditional`, `simplified`: the word (with any punctuation after it)
- `pinyin` (syllables run together, "wǒmen"), `zhuyin` (syllables spaced)
- `dictionaryIndices`: the word's index in the app's word list, if it's there

plus `english` for the whole sentence. For 我們要一起打足球比賽啦！ that is
`["我們", "要", "一起", "打", "足球", "比賽", "啦！"]`.

```swift
let result = await ExampleSentenceGenerator().generate(for: TargetWord(word))
for sentence in result.sentences {
    print(sentence.traditional, sentence.pinyin, sentence.english)
}
```

## How it works

The model writes only the traditional sentence and its English translation
(`GeneratedSentence`). Everything else is done in code (`Readings`) with
frameworks built into the OS: NaturalLanguage's `NLTokenizer` splits the
sentence into words, and Foundation's ICU transforms give the simplified form
(`Hant-Hans`) and readings (`Han-Latin`, `Latin-Bopomofo`). In testing the
model got per-character readings wrong in 12 of 12 sentences.

Readings for each word come from, in order: the target word's entry, a
`ReadingDictionary` built from the app's word list, then ICU's most common
reading of each character (which can be wrong for 樂, 為, 了 and the like).

- The model often writes simplified characters when asked for traditional,
  so its sentence is run through `Hans-Hant` first.
- Sentences that don't contain the word are dropped and topped up, up to
  three model calls.

## Checking the output

- **In the app (Debug builds):** Settings → Developer → AI Example Sentences.
- **Scratch file:** edit the word in `Sources/try-sentences/main.swift`, then
  in Xcode pick the `try-sentences` scheme and My Mac and press ⌘R (or
  `swift run try-sentences`). Output goes to the console.
- **Command line:** `swift run example-sentences` for the sample words, or
  `swift run example-sentences --data <path to output.json> 是 學習 17`.
- **Tests:** `swift test` runs the readings tests, plus `LiveGenerationTests`
  on machines with Apple Intelligence, printing each word's sentences.
