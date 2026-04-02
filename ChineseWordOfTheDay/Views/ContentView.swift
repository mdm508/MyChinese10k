//
//  ContentView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 7/11/23.
//

import SwiftUI
import CoreDataModels
import CoreData

struct ContentView: View {
    @EnvironmentObject private var ws: WordService
    @Environment(\.managedObjectContext) var context
    var body: some View {
        NavigationView {
            WordDetail()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack(spacing: 18) {
                            historyButton
                            shareButton
                            settingsButton
                        }
                    }
                }
        }
        .navigationViewStyle(.stack)
    }
}

// MARK: - Toolbar Components
private extension ContentView {
    var historyButton: some View {
        NavigationLink {
            // We initialize the Helper here, passing the context
            HistoryView(helper: HistoryHelper(context: context))
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 18, weight: .medium)) // Makes the icon match standard nav buttons
                .foregroundColor(.primary)
                .padding(8) // Increases the tap target area
        }
    }
    
    var shareButton: some View {
        Button(action: {
            shareWord(word: ws.currentWord)
        }) {
            Image(systemName: "square.and.arrow.up")
                .foregroundColor(.primary)
        }
    }
    
    var settingsButton: some View {
        NavigationLink(destination: SettingsView()) {
            Image(systemName: "gearshape.fill")
                .foregroundColor(.primary)
        }
    }
}

// MARK: - Sharing Logic
private extension ContentView {
    func shareWord(word cw: Word) {
        let url = URL(string: "https://apps.apple.com/us/app/waabl/id1671041620")!
        let itemSource = WordShareItemSource(
            word: cw.characters,
            pinyin: cw.phonetic,
            definition: cw.meanings.first?.description ?? "",
            appURL: url
        )
        
        let activityVC = UIActivityViewController(
            activityItems: [itemSource, ws.currentWord.shareText],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
}
