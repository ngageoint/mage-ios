// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EventFetch",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "EventFetch",
            targets: ["EventFetch"]
        ),
    ],
    dependencies: [
        .package(path: "../FetchOperation"),
        .package(path: "../LayerFetch"),
        .package(path: "../ServerDTO"),
        .package(path: "../APIRouter"),
        .package(path: "../Persistence"),
        .package(path: "../Event"),
        .package(path: "../User"),
        .package(path: "../UseCaseFactory"),
        .package(path: "../TestUtilities")
    ],
    targets: [
        .target(
            name: "EventFetch",
            dependencies: [
                "FetchOperation",
                "LayerFetch",
                "ServerDTO",
                "APIRouter",
                "Persistence",
                "Event",
                "User",
                "UseCaseFactory"
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error) // Treat all warnings as errors for this target
            ]
        ),
        .testTarget(
            name: "EventFetchTests",
            dependencies: ["EventFetch", "TestUtilities"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
