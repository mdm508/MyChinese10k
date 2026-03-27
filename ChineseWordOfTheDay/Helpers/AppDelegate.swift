class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let shortcutItem = options.shortcutItem {
            // Handle the shortcut right away if the app was closed
            handleShortcut(shortcutItem)
        }
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func windowScene(_ windowScene: UIWindowScene, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        // Handle the shortcut if the app was already open in the background
        handleShortcut(shortcutItem)
        completionHandler(true)
    }

    private func handleShortcut(_ item: UIApplicationShortcutItem) {
        if item.type == "com.waabl.shareApp" {
            // This is where we call your share function!
            let url = URL(string: "https://apps.apple.com/us/app/waabl/id1671041620")!
            
            // We'll use a simple helper to find the top view controller to present from
            DispatchQueue.main.async {
                let activityVC = UIActivityViewController(activityItems: ["Check out Waabl!", url], applicationActivities: nil)
                UIApplication.shared.windows.first?.rootViewController?.present(activityVC, animated: true)
            }
        }
    }
}