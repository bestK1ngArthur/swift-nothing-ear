// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftNothingEar",
    platforms: [
        .macOS(.v12),
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "SwiftNothingEar",
            targets: ["SwiftNothingEar"]
        )
    ],
    targets: [
        .target(
            name: "SwiftNothingEar",
            dependencies: []
        ),
        .testTarget(
            name: "SwiftNothingEarTests",
            dependencies: ["SwiftNothingEar"]
        )
    ]
)
