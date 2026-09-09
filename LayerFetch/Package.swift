// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LayerFetch",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "LayerFetch",
            targets: ["LayerFetch"]
        ),
    ],
    dependencies: [
        .package(path: "../FetchOperation"),
        .package(path: "../ServerDTO"),
        .package(path: "../Layer"),
        .package(path: "../APIRouter"),
        .package(path: "../TestUtilities"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.0"))
    ],
    targets: [
        .target(
            name: "LayerFetch",
            dependencies: [
                "FetchOperation",
                "ServerDTO",
                "Layer",
                "APIRouter",
                .product(name: "Alamofire", package: "Alamofire")
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error) // Treat all warnings as errors for this target
            ]
        ),
        .testTarget(
            name: "LayerFetchTests",
            dependencies: ["LayerFetch", "TestUtilities"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
