// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Pipeline",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "Pipeline",
            targets: ["Pipeline"]
        ),
    ],
    targets: [
        .target(
            name: "Pipeline",
            swiftSettings: [
                .treatAllWarnings(as: .error)
            ]
        ),
        .testTarget(
            name: "PipelineTests",
            dependencies: ["Pipeline"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
