// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Settings",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "Settings",
            targets: ["Settings"]
        ),
    ],
    dependencies: [
        .package(name: "Persistence", path: "../Persistence"),
        .package(name: "ServerDTO", path: "../ServerDTO"),
        .package(name: "Pipeline", path: "../Pipeline"),
        .package(name: "APIRouter", path: "../APIRouter")
    ],
    targets: [
        .target(
            name: "Settings",
            dependencies: [
                .product(name: "Persistence", package: "Persistence"),
                .product(name: "ServerDTO", package: "ServerDTO"),
                .product(name: "Pipeline", package: "Pipeline"),
                .product(name: "APIRouter", package: "APIRouter")
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error) // Treat all warnings as errors for this target
            ]
        ),
        .testTarget(
            name: "SettingsTests",
            dependencies: ["Settings"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
