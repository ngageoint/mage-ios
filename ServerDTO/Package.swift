// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ServerDTO",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "ServerDTO",
            targets: ["ServerDTO"]
        ),
    ],
    dependencies: [
        .package(name: "SendableExtensions", path: "../SendableExtensions"),
        .package(name: "CodableExtensions", path: "../CodableExtensions"),
        .package(url: "https://github.com/sindresorhus/ExceptionCatcher", from: "2.0.0"),
        .package(url: "https://github.com/ngageoint/simple-features-ios", from: "5.0.0"),
        .package(url: "https://github.com/ngageoint/simple-features-geojson-ios", from: "5.0.0")
    ],
    targets: [
        .target(
            name: "ServerDTO",
            dependencies: [
                .product(name: "SendableExtensions", package: "SendableExtensions"),
                .product(name: "CodableExtensions", package: "CodableExtensions"),
                .product(name: "ExceptionCatcher", package: "ExceptionCatcher"),
                .product(name: "SimpleFeatures", package: "simple-features-ios"),
                .product(name: "SimpleFeaturesGeoJSON", package: "simple-features-geojson-ios")
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error) // Treat all warnings as errors for this target
            ]
        ),
        .testTarget(
            name: "ServerDTOTests",
            dependencies: ["ServerDTO"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
