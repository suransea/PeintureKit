// swift-tools-version:5.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
        name: "PeintureKit",
        platforms: [
            .iOS(.v9),
            .tvOS(.v9)
        ],
        products: [
            .library(name: "PeintureKit", targets: ["PeintureKit"]),
        ],
        dependencies: [],
        targets: [
            .target(name: "PeintureKit", dependencies: []),
            .testTarget(name: "PeintureKitTests", dependencies: ["PeintureKit"]),
        ]
)
