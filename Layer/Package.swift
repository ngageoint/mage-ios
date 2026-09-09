// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Layer",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "Layer",
            targets: ["Layer"]
        ),
    ],
    dependencies: [
        .package(name: "Persistence", path: "../Persistence"),
        .package(name: "ServerDTO", path: "../ServerDTO")
    ],
    targets: [
        .target(
            name: "Layer",
            dependencies: [
                .product(name: "Persistence", package: "Persistence"),
                .product(name: "ServerDTO", package: "ServerDTO"),
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error) // Treat all warnings as errors for this target
            ]
        ),
        .testTarget(
            name: "LayerTests",
            dependencies: ["Layer"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
