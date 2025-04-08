// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CoreDataModels",
    platforms: [.macOS(.v10_15)], // Ensures macOS 10.15+ compatibility
    products: [
        .library(
            name: "CoreDataModels",
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
    ]
)
