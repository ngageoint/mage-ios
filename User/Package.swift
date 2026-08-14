// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "User",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "User",
            targets: ["User"]
        ),
    ],
    dependencies: [
        .package(name: "Persistence", path: "../Persistence"),
        .package(name: "ServerDTO", path: "../ServerDTO"),
        .package(name: "APIRouter", path: "../APIRouter"),
        .package(name: "UseCaseFactory", path: "../UseCaseFactory"),
        .package(url: "https://github.com/ngageoint/simple-features-ios", from: "5.0.0"),
    ],
    targets: [
        .target(
            name: "User",
            dependencies: [
                .product(name: "Persistence", package: "Persistence"),
                .product(name: "ServerDTO", package: "ServerDTO"),
                .product(name: "APIRouter", package: "APIRouter"),
                .product(name: "UseCaseFactory", package: "UseCaseFactory"),
                .product(name: "SimpleFeatures", package: "simple-features-ios"),
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error) // Treat all warnings as errors for this target
            ]
        ),
        .testTarget(
            name: "UserTests",
            dependencies: ["User"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
