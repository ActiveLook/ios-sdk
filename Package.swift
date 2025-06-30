// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "ActiveLookSDK",
    platforms: [
        .iOS(.v13),
        .watchOS(.v6),
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "ActiveLookSDK",
            targets: ["ActiveLookSDK", "Heatshrink"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.25.0"),
        .package(url: "https://github.com/NordicSemiconductor/IOS-nRF-Connect-Device-Manager.git", from: "1.9.0")
    ],
    targets: [
        .target(
            name: "ActiveLookSDK",
            dependencies: [
                "Heatshrink",
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
                .product(name: "iOSMcuManagerLibrary", package: "IOS-nRF-Connect-Device-Manager")
            ],
            path: "Sources",
            exclude: ["Heatshrink"],
            plugins: [
                .plugin(name: "ProtobufSwiftGenerator")
            ]
        ),
        .target(
            name: "Heatshrink",
            path: "Sources/Heatshrink"
        ),
        .testTarget(
            name: "ActiveLookSDKTests",
            dependencies: ["ActiveLookSDK"]
        ),
        .executableTarget(
          name: "ProtobufSwiftGeneratorExec",
          path: "Executables/ProtobufSwiftGeneratorExec"
        ),
        .plugin(
          name: "ProtobufSwiftGenerator",
          capability: .buildTool(),
          dependencies: ["ProtobufSwiftGeneratorExec"],
          path: "Plugins/ProtobufSwiftGenerator"
        )
    ]
)
