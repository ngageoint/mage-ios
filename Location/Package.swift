// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Location",
    platforms: [.iOS(.v18)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "Location",
            targets: ["Location"]
        ),
    ],
    dependencies: [
        .package(name: "Persistence", path: "../Persistence"),
        .package(name: "ServerDTO", path: "../ServerDTO"),
        .package(name: "CodableExtensions", path: "../CodableExtensions")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "Location",
            dependencies: [
                .product(name: "Persistence", package: "Persistence"),
                .product(name: "ServerDTO", package: "ServerDTO"),
                .product(name: "CodableExtensions", package: "CodableExtensions")
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error) // Treat all warnings as errors for this target
            ]
        ),
        .testTarget(
            name: "LocationTests",
            dependencies: ["Location"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
