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
    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Word.my_frequency, ascending: false)
        ]
    ) var fetchedWords: FetchedResults<Word>

}

extension ContentView: View {
    var body: some View {
        let currentWord = fetchedWords[self.offset]
        GeometryReaderCentered { geo in
            VStack(alignment: .center){
                WordView(word: currentWord.traditional, size: geo.size)
                Text(currentWord.zhuyin)
                List(currentWord.my_meanings, id: \.self){
                    Text($0)
                }
                Text(currentWord.index.description)
                Spacer()
                Button("->"){
                    self.offset += 10
                }
            }
        }.onAppear{
            print(currentWord)
        }
    }
}

