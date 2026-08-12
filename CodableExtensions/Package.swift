// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CodableExtensions",
    products: [
        .library(
            name: "CodableExtensions",
            targets: ["CodableExtensions"]
        ),
    ],
    targets: [
        .target(
            name: "CodableExtensions",
            swiftSettings: [
                .treatAllWarnings(as: .error) // Treat all warnings as errors for this target
            ]
        ),
        .testTarget(
            name: "CodableExtensionsTests",
            dependencies: ["CodableExtensions"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
