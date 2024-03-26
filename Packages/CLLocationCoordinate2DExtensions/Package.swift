// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "CLLocationCoordinate2DExtensions",
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "CLLocationCoordinate2DExtensions",
            targets: ["CLLocationCoordinate2DExtensions"]),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "CLLocationCoordinate2DExtensions"),
        .testTarget(
            name: "CLLocationCoordinate2DExtensionsTests",
            dependencies: ["CLLocationCoordinate2DExtensions"]),
    ]
)
