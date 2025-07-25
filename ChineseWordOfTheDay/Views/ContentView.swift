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

}

extension ContentView: View {
    var body: some View {
           TabView {
               NavigationView {
                   WordDetailContainer()
                       .navigationTitle(chineseDate())
                       .navigationBarTitleDisplayMode(.inline)
               }
               .tabItem {
                   Label("Today", systemImage: "sun.max.fill")
               }
               .tag(0)

               NavigationView {
                   SettingsView()
                       .navigationTitle("Settings")
               }
               .tabItem {
                   Label("Settings", systemImage: "gearshape.fill")
               }
               .tag(1)
           }
       }
}
