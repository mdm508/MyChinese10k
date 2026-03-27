//
//  WordShareItemSource.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 3/27/26.
//


import LinkPresentation
import UIKit

class WordShareItemSource: NSObject, UIActivityItemSource {
    let word: String
    let pinyin: String
    let definition: String
    let appURL: URL

    init(word: String, pinyin: String, definition: String, appURL: URL) {
        self.word = word
        self.pinyin = pinyin
        self.definition = definition
        self.appURL = appURL
        super.init()
    }

    // This returns the actual URL to be shared
    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return appURL
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return appURL
    }

    // This is the "Banner" magic 🪄
    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        
        // The Large Title
        metadata.title = "Today's word is \(word) (\(pinyin))"
        
        // The Subtitle/Description
        metadata.originalURL = appURL
        if let image = UIImage(named: "appstore1024") {
            metadata.iconProvider = NSItemProvider(object: image)
            print("Successfully loaded icon for share banner! ✅")
        } else {
            print("Failed to load image named appstore1024 ❌")
        }
        return metadata
    }
}
