//
//  LoadingView.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 3/15/26.
//


import SwiftUI

struct LoadingView: View {

    var body: some View {
        VStack(spacing: 20) {

            ProgressView()
                .progressViewStyle(CircularProgressViewStyle())

            Image("AppIconDisplay")
                .resizable()
                .frame(width: 96, height: 96)
                .cornerRadius(22)

            Text("Loading words…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}
