//
//  HistoryStreamView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 4/2/26.
//


import SwiftUI

struct HistoryStreamView: View {
    @ObservedObject var helper: HistoryHelper
    let startMonth: String
    
    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 40) {
                    ForEach(helper.sections) { section in
                        // The Section Landmark
                        sectionMarker(section.monthTitle)
                            .id(section.monthTitle)
                        
                        ForEach(section.cards) { card in
                            // Reuse the detail content view we built earlier
                            // but styled for a continuous list
                            StreamCardItem(card: card, flipTrigger: helper.flipTrigger)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical, 20)
            }
            .background(Color(UIColor.systemGroupedBackground))
            .navigationTitle("Study Stream")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Auto-scroll to the month they tapped on
                proxy.scrollTo(startMonth, anchor: .top)
            }
        }
    }
    
    private func sectionMarker(_ title: String) -> some View {
        Text(title)
            .font(.system(size: 14, weight: .black, design: .rounded))
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color.blue)
            .foregroundColor(.white)
            .clipShape(Capsule())
            .padding(.top, 40)
    }
}