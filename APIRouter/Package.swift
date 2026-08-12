// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "APIRouter",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "APIRouter",
            targets: ["APIRouter"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.0"))
    ],
    targets: [
        .target(
            name: "APIRouter",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire")
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error) // Treat all warnings as errors for this target
            ]
        ),
        .testTarget(
            name: "APIRouterTests",
            dependencies: ["APIRouter"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
