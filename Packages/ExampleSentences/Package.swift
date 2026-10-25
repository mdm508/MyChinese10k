// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "ExampleSentences",
    platforms: [
        // Foundation Models ships with iOS 26 / macOS 26.
        .iOS(.v26),
        .macOS(.v26)
    ],
    products: [
        .library(
            name: "ExampleSentences",
            targets: ["ExampleSentences"]
        ),
        .executable(
            name: "example-sentences",
            targets: ["example-sentences"]
        ),
        .executable(
            name: "try-sentences",
            targets: ["try-sentences"]
        )
    ],
    dependencies: [
        .package(path: "../CoreDataModels")
    ],
    targets: [
        .target(
            name: "ExampleSentences",
            dependencies: ["CoreDataModels"]
        ),
        .executableTarget(
            name: "example-sentences",
            dependencies: ["ExampleSentences", "CoreDataModels"]
        ),
        .executableTarget(
            name: "try-sentences",
            dependencies: ["ExampleSentences", "CoreDataModels"]
        ),
        .testTarget(
            name: "ExampleSentencesTests",
            dependencies: ["ExampleSentences", "CoreDataModels"]
        )
    ]
)
