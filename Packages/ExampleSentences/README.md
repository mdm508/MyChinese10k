# ExampleSentences

Generates Chinese example sentences for a word with Apple's on-device
Foundation Models framework (iOS 26 / macOS 26, Apple Intelligence on).

Input is any `WordRepresentable` (the Core Data `Word` or a `MockWord`),
wrapped in a `TargetWord`. Output is an `ExampleSentenceResult` holding
`ExampleSentence`s, each with:

- `traditional` and `simplified` sentences
- `pinyin` and `zhuyin`: arrays with one syllable per Chinese character
  (punctuation is skipped), lining up with `characters`
- `english`

```swift
let result = await ExampleSentenceGenerator().generate(for: TargetWord(word))
for sentence in result.sentences {
    print(sentence.traditional, sentence.pinyin, sentence.english)
}
```

## How it works

The model writes only the traditional sentence and its English translation
(`GeneratedSentence`). Everything else is derived in code (`Readings`) with
the ICU transforms built into Foundation: `Hant-Hans` for the simplified
sentence, `Han-Latin` for pinyin and `Latin-Bopomofo` for zhuyin. In testing
the model got per-character pinyin and zhuyin wrong in 12 of 12 sentences,
and these transforms were right in every case.

- The model often writes simplified characters when asked for traditional,
  so its sentence is run through `Hans-Hant` first.
- ICU picks each character's most common reading, which can be wrong for
  characters with several readings (行, 了, 長). Readings for the target
  word itself come from its dictionary entry.
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
