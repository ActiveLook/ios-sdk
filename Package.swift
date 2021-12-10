// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "ActiveLookSDK",
    platforms: [
        .iOS(.v10),
        .watchOS(.v6)
    ],
    products: [
        .library(
            name: "ActiveLookSDK",
            targets: ["ActiveLookSDK"]
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ActiveLookSDK",
            dependencies: [],
            path: "Classes"
        )
    ]
)
