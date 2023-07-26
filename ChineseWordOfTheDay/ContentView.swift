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

    @FetchRequest(
        sortDescriptors: [
            NSSortDescriptor(keyPath: \Word.my_frequency, ascending: false)
        ]
    ) var fetchedResults: FetchedResults<Word>

}

extension ContentView: View {
    var body: some View {
        VStack {
            Text(fetchedResults[0].my_traditional)
        }
        .padding()
    }
}

