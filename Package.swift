// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EssentialFeed",
    platforms: [.macOS(.v10_15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "EssentialFeed",
            targets: ["EssentialFeed"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(name: "EssentialFeed"),
        .target(name: "TestHelpers"),
        .testTarget(
            name: "EssentialFeedTests",
            dependencies: ["EssentialFeed", "TestHelpers"]
        ),
        .testTarget(
            name: "EssentialFeedAPIEndToEndTests",
            dependencies: ["EssentialFeed", "TestHelpers"]
        )
    ]
)
