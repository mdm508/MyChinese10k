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
            HistoryView()
        } label: {
            Image(systemName: "clock.arrow.circlepath")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
                .padding(8)
        }
    }
    var settingsButton: some View {
        NavigationLink(destination: SettingsView()) {
            Image(systemName: "gearshape.fill")
                .foregroundColor(.primary)
        }
    }
}

