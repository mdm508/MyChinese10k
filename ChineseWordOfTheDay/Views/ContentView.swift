//
//  ContentView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 7/11/23.
//

import SwiftUI
import CoreDataModels
import CoreData

struct ContentView {
    @Environment(\.managedObjectContext) private var context
    @FetchRequest(sortDescriptors: [NSSortDescriptor(keyPath: \WordIndex.current, ascending: true)])
    var wordIndexResults: FetchedResults<WordIndex>
    var wordIndex: WordIndex? {
        if let wi = wordIndexResults.first {
            return wi
        }
        return nil
    }
    @State var currentWord: Word?
    init(){
        let request: NSFetchRequest<WordIndex> = WordIndex.fetchRequest()
        request.fetchLimit = 1
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WordIndex.current, ascending: true)]
        _wordIndexResults = FetchRequest(fetchRequest: request)
    }
}

extension ContentView: View {
    var body: some View {
        VStack {
            if let currentWord = self.currentWord {
                GeometryReaderCentered { geo in
                    VStack(alignment: .center) {
                        WordView(word: currentWord.traditional, size: geo.size)
                        Text(currentWord.zhuyin)
                        ZStack(alignment: .bottomTrailing) {
                            List(currentWord.meanings, id: \.self) {
                                Text($0)
                            }
                            HStack {
                                Spacer()
                                BigGreenButton(parentSize: geo.size) {
                                    if let wi = self.wordIndex {
                                        wi.current += 1
                                        try! context.save()
                                        Task {
                                            if let w = self.currentWord {
                                                await updateCurrentWordStatusToSeen(word: w, context: self.context)
                                                await self.loadCurrentWord()
                                            }
                                        }
                                    }

                                }
                            }.background(Color.clear)
                        }
                    }
                }
            } else {
                Image("ipad76")
            }
        }
        .onAppear {
            Task {
                await loadCurrentWord() // ✅ Fetch word when view appears
            }
        }
    }
}
extension ContentView {
    private func loadCurrentWord() async {
        await context.perform {
            var wordIndex: WordIndex
            if let existingIndex = wordIndexResults.first {
                wordIndex = existingIndex
            } else {
                wordIndex = WordIndex(context: context)
                wordIndex.current = 1
                do {
                    try context.save()
                } catch {
                    print("Failed to save WordIndex: \(error)")
                }
            }
            self.currentWord = Word.fetchWord(at: wordIndex.current, context: context)
        }
    }
}
