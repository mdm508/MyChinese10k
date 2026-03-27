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
    @EnvironmentObject private var ws: WordService
}

extension ContentView: View {
    var body: some View {
        NavigationView {
            WordDetail()
                .toolbar {
                    ToolbarItem(placement: .navigationBarTrailing) {
                        NavigationLink(destination: SettingsView()) {
                            Image(systemName: "gearshape.fill")
                                .foregroundColor(.primary)
                        }
                    }
                    ToolbarItem(placement: .navigationBarTrailing) {
                        HStack {
                            // The Share Button
                            Button(action: {
                                shareWord(word: ws.currentWord)
                            }) {
                                Image(systemName: "square.and.arrow.up")
                            }
                        }
                    }
                    
  
                }
        }.navigationViewStyle(.stack)
    }
    
    func shareWord(word cw: Word) {
        let url = URL(string: "https://apps.apple.com/us/app/waabl/id1671041620")!
        let word = cw.characters
        let pinyin = cw.phonetic
        let definition = cw.meanings.first?.description ?? ""
        // Create our rich metadata provider
        let itemSource = WordShareItemSource(
            word: word,
            pinyin: pinyin,
            definition: definition,
            appURL: url
        )
        // We pass the itemSource to the share sheet
        let activityVC = UIActivityViewController(activityItems: [itemSource,ws.currentWord.shareText], applicationActivities: nil)
        // Standard UIKit presentation logic
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootVC = windowScene.windows.first?.rootViewController {
            rootVC.present(activityVC, animated: true)
        }
    }
    
}
