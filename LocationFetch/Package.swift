// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "LocationFetch",
    platforms: [.iOS(.v18)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "LocationFetch",
            targets: ["LocationFetch"]
        ),
    ],
    dependencies: [
        .package(name: "FetchOperation", path: "../FetchOperation"),
        .package(name: "ServerDTO", path: "../ServerDTO"),
        .package(name: "APIRouter", path: "../APIRouter"),
        .package(name: "User", path: "../User"),
        .package(name: "Persistence", path: "../Persistence"),
        .package(name: "Location", path: "../Location"),
        .package(name: "UseCaseFactory", path: "../UseCaseFactory"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "LocationFetch",
            dependencies: [
                .product(name: "FetchOperation", package: "FetchOperation"),
                .product(name: "ServerDTO", package: "ServerDTO"),
                .product(name: "APIRouter", package: "APIRouter"),
                .product(name: "User", package: "User"),
                .product(name: "Persistence", package: "Persistence"),
                .product(name: "Location", package: "Location"),
                .product(name: "UseCaseFactory", package: "UseCaseFactory"),
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error) // Treat all warnings as errors for this target
            ]
        ),
        .testTarget(
            name: "LocationFetchTests",
            dependencies: ["LocationFetch"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
