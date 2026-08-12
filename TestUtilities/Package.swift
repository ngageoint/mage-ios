// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "TestUtilities",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "TestUtilities",
            targets: ["TestUtilities"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/AliSoftware/OHHTTPStubs", from: "9.1.0"),
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.0")),
        .package(name: "Persistence", path: "../Persistence")
    ],
    targets: [
        .target(
            name: "TestUtilities",
            dependencies: [
                .product(name: "Persistence", package: "Persistence"),
                .product(name: "Alamofire", package: "Alamofire"),
                .product(name: "OHHTTPStubs", package: "OHHTTPStubs"),
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs")
            ],
            resources: [.process("Resources")]
        ),
        .testTarget(
            name: "TestUtilitiesTests",
            dependencies: ["TestUtilities"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
