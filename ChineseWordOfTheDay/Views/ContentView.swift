//
//  ContentView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 7/11/23.
//

import SwiftUI

struct ContentView {
    @StateObject var viewModel: WordViewModel
}
extension ContentView: View {
    var body: some View {
        if let currentWord = viewModel.currentWord {
            GeometryReaderCentered { geo in
                VStack(alignment: .center){
                    WordView(word: currentWord.traditional, size: geo.size)
                    Text(currentWord.zhuyin)
                    ZStack(alignment: .bottomTrailing){
                        List(currentWord.meanings, id: \.self){
                            Text($0)
                        }
                        HStack{
                            Spacer()
                            BigGreenButton(size: geo.size, action: self.viewModel.updateCurrentWordStatusToSeen)
                        }.background(Color.clear)
                    }
         
                }
            }
        } else {
            Text("Congrats you learned all the words!")
        }
    }
}
        
