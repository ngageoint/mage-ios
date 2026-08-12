// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FetchOperation",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "FetchOperation",
            targets: ["FetchOperation"]
        ),
    ],
    dependencies: [
        .package(name: "ProgressReportingJSONDecoder", path: "../ProgressReportingJSONDecoder"),
        .package(name: "Pipeline", path: "../Pipeline")
    ],
    targets: [
        .target(
            name: "FetchOperation",
            dependencies: [
                .product(name: "ProgressReportingJSONDecoder", package: "ProgressReportingJSONDecoder"),
                .product(name: "Pipeline", package: "Pipeline")
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error)
            ]
        ),
        .testTarget(
            name: "FetchOperationTests",
            dependencies: ["FetchOperation"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
