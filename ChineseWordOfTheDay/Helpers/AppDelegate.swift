//
//  AppDelegate.swift
//  ChineseWordOfTheDay
//
//  Created by Matthew McLaughlin on 3/27/26.
//

import UIKit

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        handleShortcut(shortcutItem)
        completionHandler(true)
    }
    func handleShortcut(_ item: UIApplicationShortcutItem) {
        if item.type == "com.waabl.shareApp" {
            let url = URL(string: "https://apps.apple.com/us/app/waabl/id1671041620")!
            let message = "Check out Waabl! Learn a new Chinese word every day."
            
            DispatchQueue.main.async {
                // 2. Fix for the 'windows' deprecation:
                // We find the active window through the connected scenes.
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                   let rootVC = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController {
                    
                    let activityVC = UIActivityViewController(activityItems: [message, url], applicationActivities: nil)
                    rootVC.present(activityVC, animated: true)
                }
            }
        }
    }
}
