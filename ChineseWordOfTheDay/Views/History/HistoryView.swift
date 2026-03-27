//
//  HistoryView.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 3/27/26.
//


import SwiftUI
import CoreData


struct HistoryView: View {
    @StateObject private var helper: HistoryHelper
    
    /// LITERATE NOTE:
    /// Initialized with the context passed from the NavigationLink in ContentView.
    init(context: NSManagedObjectContext) {
        _helper = StateObject(wrappedValue: HistoryHelper(context: context))
    }
    
    private let columns = [GridItem(.adaptive(minimum: 140), spacing: 16)]
    
    var body: some View {
        ScrollView {
            LazyVGrid(columns: columns, spacing: 16, pinnedViews: [.sectionHeaders]) {
                ForEach(helper.sections) { section in
                    Section(header: sectionHeader(section.title)) {
                        ForEach(section.cards) { card in
                            HistoryCard(card: card)
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("History")
        .onAppear {
            helper.reload()
        }
    }
    
    /// Sticky header for the date sections
    private func sectionHeader(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.bold())
            .foregroundColor(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.vertical, 8)
            .background(Color(UIColor.systemBackground).opacity(0.9))
    }
}
