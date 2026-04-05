//
//  WordDetailView.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 6/9/25.
//

import SwiftUI
import CoreDataModels
import Persistence
import CoreData

/**
 Displays the current Word. If all word's have been completed exits.
 */
@MainActor
struct WordDetail {
    // MARK: - State
    @EnvironmentObject private var ws: WordService
    @State private var isProcessingNextWord = false
    @StateObject private var speechVM = SpeechViewModel()
}

// MARK: - Body Definition
extension WordDetail: View {
    var body: some View {
        Group {
            if ws.currentWord.index < ws.maxIndex {
                GeometryReaderCentered { geo in
                    ZStack {
                        content(in: geo)
                    }
                }
            } else {
                // Fallback when all words have been completed
                VStack{
                    Text("Congratulations")
                    Image("AppIconDisplay")
                        .resizable()
                        .frame(width: 96, height: 96)
                        .cornerRadius(22)
                    Text("You learned \(ws.maxIndex) words")
                }
            }
        }
    }
}
// MARK: - Layout & Subviews
private extension WordDetail {
    /// The main content layout inside the GeometryReader.
    func content(in geo: GeometryProxy) -> some View {
        VStack(alignment: .center) {
            // Learning progress bar
            Group {
                Text(ws.currentWord.phonetic) // or word.phonetic if you add it to MockWord
                    .font(.headline)
                WordView(word: ws.currentWord.characters, size: geo.size)
                .foregroundColor(speechVM.isSpeaking ? .blue : .terracotta)

            }.onTapGesture {
                self.speechVM.speak(ws.currentWord.traditional, .chineseTaiwan)
            }
            meaningsList

            nextButton(in: geo)
                
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: .settingDidChange),
                   perform: {_ in ws.settingsUpdated()})
    }
    /// A scrollable list of the word's meanings.
    var meaningsList: some View {
        List(ws.currentWord.meanings, id: \.self) { meaning in
            Text(meaning)
            // 1. Make the row react to a tap
                        .onTapGesture {
                            // 2. Tell the VM to speak the specific meaning in English
                            speechVM.speak(meaning, .english)
                        }
        }
        .listStyle(.plain)
        .layoutPriority(1)
    }
    /// The Next button centered at the bottom.
    func nextButton(in geo: GeometryProxy) -> some View {
        VStack {
            Spacer()
            BigGreenButton(parentSize: geo.size) {
                ws.markWordAsSeen()
            }
            .disabled(isProcessingNextWord)
            .opacity(isProcessingNextWord ? 0.6 : 1.0)
            .padding(.bottom, 40)
        }
    }
}
