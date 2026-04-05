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
    func content(in geo: GeometryProxy) -> some View {
        VStack(alignment: .center) {
            Group {
                WordView(word: ws.currentWord.characters, size: geo.size)
                .foregroundColor(speechVM.isSpeaking ? .blue : .terracotta)
                Text(ws.currentWord.phonetic)
                    .font(.headline)
            }
            .onTapGesture {
                self.speechVM.speak(ws.currentWord.traditional, .chineseTaiwan)
            }
            Spacer()
            meaningsList
            nextButton(in: geo)
        }
        .padding()
        .onReceive(NotificationCenter.default.publisher(for: .settingDidChange),
                   perform: {_ in ws.settingsUpdated()})
    }
    var meaningsList: some View {
        List(ws.currentWord.meanings, id: \.self) { meaning in
            Text(meaning)
                        .onTapGesture {
                            speechVM.speak(meaning, .english)
                        }
        }
        .listStyle(.plain)
        .layoutPriority(1)
    }
    func nextButton(in geo: GeometryProxy) -> some View {
        VStack {
            BigGreenButton(parentSize: geo.size) {
                ws.markWordAsSeen()
            }
            .disabled(isProcessingNextWord)
            .opacity(isProcessingNextWord ? 0.6 : 1.0)
            .padding(.bottom, 40)
        }
    }
}
