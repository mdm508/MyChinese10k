//
//  MediumWordWidgetView.swift
//  ChineseWordOfTheDay
//
//  Created by m on 3/15/26.
//


import SwiftUI
import WidgetKit

struct MediumWordWidgetView: View {
    let entry: WordEntry

    var body: some View {
        if let selectedMeaning = entry.selectedMeaning, !selectedMeaning.isEmpty {
            HStack(spacing: 10) {
                VStack(spacing: 4) {
                    Text(entry.word.phonetic)
                        .font(.footnote.italic())
                        .lineLimit(1)
                        .minimumScaleFactor(0.4)

                    ResizingCharacterText(characters: entry.word.characters)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.white.opacity(0.10))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(Color.white.opacity(0.18), lineWidth: 1)
                )
                .shadow(color: Color.black.opacity(0.12), radius: 3, x: 0, y: 1)

                Text(selectedMeaning)
                    .font(.system(size: 13))
                    .lineLimit(3)
                    .minimumScaleFactor(0.4)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                    .multilineTextAlignment(.leading)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            VStack(spacing: 6) {
                Text(entry.word.characters)
                    .font(.system(size: wordOnlyFontSize(), weight: .bold, design: .default))
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    private func wordOnlyFontSize() -> CGFloat {
        let count = max(entry.word.characters.count, 1)

        switch count {
        case 1:
            return 120
        case 2:
            return 90
        case 3:
            return 80
        default:
            return 100
        }
    }
}

struct MediumWordWidgetView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ForEach(WidgetPreviewEntries.allSmall.indices, id: \.self) { index in
                let previewCase = WidgetPreviewEntries.allSmall[index]
                preview(entry: previewCase.entry, name: previewCase.name)
            }
        }
    }

    static func preview(entry: WordEntry, name: String) -> some View {
        let view = MediumWordWidgetView(entry: entry)
            .previewContext(WidgetPreviewContext(family: .systemMedium))
            .previewDisplayName(name)

        if #available(iOS 17.0, *) {
            return AnyView(
                view.containerBackground(for: .widget) {
                    Color.clear
                }
            )
        } else {
            return AnyView(view)
        }
    }
}
