// swift-tools-version:5.10

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
            targets: ["ActiveLookSDK", "Heatshrink"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/NordicSemiconductor/IOS-nRF-Connect-Device-Manager.git", exact: "1.9.0")
    ],
    targets: [
        .target(
            name: "ActiveLookSDK",
            dependencies: [
                "Heatshrink",
                .product(name: "iOSMcuManagerLibrary", package: "IOS-nRF-Connect-Device-Manager")
            ],
            path: "Sources",
            exclude: ["Heatshrink"],
            swiftSettings: swiftSettings
        ),
        .target(
            name: "Heatshrink",
            path: "Sources/Heatshrink"
        ),
        .testTarget(
            name: "ActiveLookSDKTests",
            dependencies: ["ActiveLookSDK"]
        )
    ]
)

let swiftSettings: [SwiftSetting] = [
    .enableUpcomingFeature("BareSlashRegexLiterals"),
    .enableUpcomingFeature("ConciseMagicFile"),
    .enableUpcomingFeature("DeprecateApplicationMain"),
    .enableUpcomingFeature("DisableOutwardActorInference"),
    .enableUpcomingFeature("DynamicActorIsolation"),
    .enableUpcomingFeature("ForwardTrailingClosures"),
    .enableUpcomingFeature("GlobalActorIsolation"),
    .enableUpcomingFeature("ImplicitlyOpenedExistentials"),
    .enableUpcomingFeature("ImportObjCForwardDeclarations"),
    .enableUpcomingFeature("InferSendableFromMethodsAndKeyPaths"),
    .enableUpcomingFeature("IsolatedDefaultValues"),
    .enableUpcomingFeature("IsolatedGlobals"),
    .enableUpcomingFeature("NonFrozenEnumExhaustivity"),
    .enableUpcomingFeature("RegionBasedIsolation"),
    .enableUpcomingFeature("RequireExplicitAny"),
    .enableUpcomingFeature("MemberImportVisibility"),
    .enableUpcomingFeature("DefaultInternalImports"),
    .enableUpcomingFeature("StrictConcurrency")
]
