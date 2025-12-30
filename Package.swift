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
    dependencies: [.package(url: "https://github.com/NordicSemiconductor/IOS-nRF-Connect-Device-Manager", from: "1.0.0")],
    targets: [
        .target(
            name: "ActiveLookSDK",
            dependencies: ["Heatshrink", .product(name: "iOSMcuManagerLibrary", package: "IOS-nRF-Connect-Device-Manager")],
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
