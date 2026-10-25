# ExampleSentences

Generates Chinese example sentences for a word with Apple's on-device
Foundation Models framework (iOS 26 / macOS 26, Apple Intelligence on).

Input is any `WordRepresentable` (the Core Data `Word` or a `MockWord`),
wrapped in a `TargetWord`. Output is an `ExampleSentenceResult` with sentences
for each sense of the word.

- **Senses** are the entries of `meanings`, in order. Synonyms separated by
  `;` inside one entry are one sense. Dictionary notes such as `also pr. …`,
  `variant of …` and `CL:…` are skipped.
- The generator makes one model request per sense (a fresh session each time)
  and asks for two sentences. A sentence counts only if it contains the word,
  in either script; up to three requests are made per sense to get two.
- When a word has several senses, a second model call (the sense check) says
  which meaning each sentence uses. Sentences it agrees with are listed first
  and the sense gets a ✓; otherwise it gets a ?. The check is only a hint: it
  is good at catching future 會 or possessive 的 in the wrong sense, but it
  misreads compounds like 聚會 and near-synonymous senses (say / speak / tell).
  It roughly triples run time; turn it off with
  `ExampleSentenceGenerator(checksSense: false)` or `--no-sense-check`.

```swift
let result = await ExampleSentenceGenerator().generate(for: TargetWord(word))
result.coversEverySense   // every sense has a sentence that uses the word
print(result.report)
```

## Checking the output

- **In the app (Debug builds):** Settings → Developer → AI Example Sentences.
  Pick the current word, one of the next ten, or a sample word, and tap Generate.
- **Command line (Mac):**
  ```sh
  cd Packages/ExampleSentences
  swift run example-sentences                       # sample words
  swift run example-sentences --data ../../../chineseWordOfTheDayDataSet/output.json 是 學習 17
  ```
- **Tests:** `swift test` runs the sense parsing tests everywhere and
  `LiveGenerationTests` on machines with Apple Intelligence, printing each
  word's sentences to the log.
