//
//  ContentView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 7/11/23.
//

import SwiftUI

struct ContentView {
    @StateObject var viewModel: WordViewModel
    @State private var isSyncingToCloud = true
    @State private var message: String = ""
}
extension ContentView: View {
    var body: some View {
        if self.isSyncingToCloud {
            Text("iCloud is syncing").task(priority: .low){
                print("started icloud sync")
                self.isSyncingToCloud = true
                await updateAllLocalStatus()
                print("icloud sync completed")
                self.isSyncingToCloud = false
                self.viewModel.refresh()
            }
        }
        else {
            let currentWord = viewModel.currentWord
            GeometryReaderCentered { geo in
                VStack(alignment: .center){
                    WordView(word: currentWord.traditional, size: geo.size)
                    Text(currentWord.zhuyin)
                    List(currentWord.meanings, id: \.self){
                        Text($0)
                    }
                    Text(currentWord.index.description)
                    Spacer()
                    Button("->"){
                        self.viewModel.updateCurrentWordStatusToSeen()
                    }
                    Text(message)
                }
            }
        }
    }
}
        
