// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoreDataModels",
    platforms: [
        .iOS(.v15), // Ensures iOS 15.0+ compatibility
        .macOS(.v10_15) // Ensures macOS 10.15+ compatibility
    ],
    products: [
        // Dynamic so the app, the widget and Persistence.framework all share one copy
        // of the Core Data classes instead of each linking its own.
        .library(
            name: "CoreDataModels",
            type: .dynamic,
            targets: ["CoreDataModels"]
        ),
    ],
    targets: [
        .target(
            name: "CoreDataModels",
            resources: [
                .process("WordModel.xcdatamodel")
            ]
        )
    ],
    swiftLanguageModes: [.v5]
)
