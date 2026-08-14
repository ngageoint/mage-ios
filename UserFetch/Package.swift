// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "UserFetch",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "UserFetch",
            targets: ["UserFetch"]
        ),
    ],
    dependencies: [
        .package(name: "FetchOperation", path: "../FetchOperation"),
        .package(name: "ServerDTO", path: "../ServerDTO"),
        .package(name: "APIRouter", path: "../APIRouter"),
        .package(name: "User", path: "../User")
    ],
    targets: [
        .target(
            name: "UserFetch",
            dependencies: [
                .product(name: "FetchOperation", package: "FetchOperation"),
                .product(name: "ServerDTO", package: "ServerDTO"),
                .product(name: "APIRouter", package: "APIRouter"),
                .product(name: "User", package: "User")
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error) // Treat all warnings as errors for this target
            ]
        ),
        .testTarget(
            name: "UserFetchTests",
            dependencies: ["UserFetch"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
