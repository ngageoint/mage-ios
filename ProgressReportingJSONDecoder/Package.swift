// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "ProgressReportingJSONDecoder",
    products: [
        .library(
            name: "ProgressReportingJSONDecoder",
            targets: ["ProgressReportingJSONDecoder"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", .upToNextMajor(from: "5.10.0")),
    ],
    targets: [
        .target(
            name: "ProgressReportingJSONDecoder",
            dependencies: [
                .product(name: "Alamofire", package: "Alamofire")
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error) // Treat all warnings as errors for this target
            ]
        ),
        .testTarget(
            name: "ProgressReportingJSONDecoderTests",
            dependencies: ["ProgressReportingJSONDecoder"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
