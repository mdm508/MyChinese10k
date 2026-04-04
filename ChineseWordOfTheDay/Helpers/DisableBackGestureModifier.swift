import SwiftUI

// This is the part your code is missing!
extension View {
    func disableSwipeBack() -> some View {
        self.onAppear {
            // This finds the "back gesture" in the background and kills it
            UINavigationController.disableSwipeGesture()
        }
    }
}

// This helper talks to the underlying iOS navigation system
extension UINavigationController {
    static func disableSwipeGesture() {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootViewController = windowScene.windows.first(where: { $0.isKeyWindow })?.rootViewController else {
            return
        }
        findNavigationController(from: rootViewController)?.interactivePopGestureRecognizer?.isEnabled = false
    }

    private static func findNavigationController(from viewController: UIViewController) -> UINavigationController? {
        if let nav = viewController as? UINavigationController { return nav }
        for child in viewController.children {
            if let nav = findNavigationController(from: child) { return nav }
        }
        return nil
    }
}
