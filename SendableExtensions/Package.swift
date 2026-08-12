// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SendableExtensions",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "SendableExtensions",
            targets: ["SendableExtensions"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/ngageoint/simple-features-ios", from: "5.0.0"),
        .package(url: "https://github.com/ngageoint/simple-features-geojson-ios", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "SendableExtensions",
            dependencies: [
                .product(name: "SimpleFeatures", package: "simple-features-ios"),
                .product(name: "SimpleFeaturesGeoJSON", package: "simple-features-geojson-ios")
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error) // Treat all warnings as errors for this target
            ]
        ),
        .testTarget(
            name: "SendableExtensionsTests",
            dependencies: ["SendableExtensions"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
