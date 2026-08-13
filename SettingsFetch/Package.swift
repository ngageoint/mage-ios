// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SettingsFetch",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "SettingsFetch",
            targets: ["SettingsFetch"]
        ),
    ],
    dependencies: [
        .package(name: "Persistence", path: "../Persistence"),
        .package(name: "ServerDTO", path: "../ServerDTO"),
        .package(name: "APIRouter", path: "../APIRouter"),
        .package(name: "FetchOperation", path: "../FetchOperation"),
        .package(name: "UseCaseFactory", path: "../UseCaseFactory"),
        .package(name: "Settings", path: "../Settings")
    ],
    targets: [
        .target(
            name: "SettingsFetch",
            dependencies: [
                .product(name: "Persistence", package: "Persistence"),
                .product(name: "ServerDTO", package: "ServerDTO"),
                .product(name: "APIRouter", package: "APIRouter"),
                .product(name: "FetchOperation", package: "FetchOperation"),
                .product(name: "UseCaseFactory", package: "UseCaseFactory"),
                .product(name: "Settings", package: "Settings")
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error) // Treat all warnings as errors for this target
            ]
        ),
        .testTarget(
            name: "SettingsFetchTests",
            dependencies: ["SettingsFetch"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
