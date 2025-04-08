// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "WordBuilder",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(
            name: "WordBuilder",
            targets: ["WordBuilder"]
        )
    ],
    dependencies: [
        .package(path: "../CoreDataModels")
    ],
    targets: [
        .executableTarget(
            name: "WordBuilder",
            dependencies: ["CoreDataModels"],
            resources: [
                .process("Resources/output.json") // e.g., your input JSON if needed
            ]
        )
    ]
)
