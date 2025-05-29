// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ViewExtensions",
    platforms: [.iOS(.v16)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "ViewExtensions",
            targets: ["ViewExtensions"]),
    ],
    dependencies: [
        .package(name: "MAGEStyle", path: "../MAGEStyle")
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "ViewExtensions",
            dependencies: ["MAGEStyle"]
        ),
        .testTarget(
            name: "ViewExtensionsTests",
            dependencies: ["ViewExtensions"]),
    ]
)
