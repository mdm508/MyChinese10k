//
//  ContentView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 7/11/23.
//

import SwiftUI
import WordFramework




struct ContentView {
    @Environment(\.managedObjectContext) private var viewContext
    @State var offset = 0
    @StateObject var viewModel: WordViewModel = WordViewModel()

}

extension ContentView: View {
    var body: some View {
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
                    self.viewModel.updateCurrentWordStatus(newStatus: 1)
                }
            }
        }
    }
}

