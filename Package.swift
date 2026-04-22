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
            targets: ["ActiveLookSDK","Heatshrink"]),
        .library(
            name: "ActiveLookProtobuf",
            targets: ["ActiveLookProtobuf"])
    ],
    dependencies: [.package(url: "https://github.com/NordicSemiconductor/IOS-nRF-Connect-Device-Manager", from: "1.0.0"),
                   .package(url: "https://github.com/apple/swift-protobuf", from: "1.0.0")],
    targets: [
        .target(
            name: "ActiveLookSDK",
            dependencies: ["Heatshrink", .product(name: "iOSMcuManagerLibrary", package: "IOS-nRF-Connect-Device-Manager")],
            path: "Sources",
            exclude: ["Heatshrink", "ActiveLookProtobuf"]),
        .target(
            name: "Heatshrink",
            path: "Sources/Heatshrink"),
        .target(
            name: "ActiveLookProtobuf",
            dependencies: [.product(name: "SwiftProtobuf", package: "swift-protobuf")],
            path: "Sources/ActiveLookProtobuf"),
        .testTarget(
            name: "ActiveLookSDKTests",
            dependencies: ["ActiveLookSDK"])
    ]
)
