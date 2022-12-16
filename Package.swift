// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "ActiveLookSDK",
    platforms: [
        .iOS(.v13),
        .watchOS(.v6),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "ActiveLookSDK",
            targets: ["ActiveLookSDK","Heatshrink"])
    ],
    dependencies: [],
    targets: [
        .target(
            name: "ActiveLookSDK",
            dependencies: ["Heatshrink"],
            path: "Sources",
            exclude: ["Heatshrink"]),
        .target(
            name: "Heatshrink",
            path: "Sources/Heatshrink"),
        .testTarget(
            name: "ActiveLookSDKTests",
            dependencies: ["ActiveLookSDK"]),
    ]
)
