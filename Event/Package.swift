// swift-tools-version: 6.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Event",
    platforms: [.iOS(.v18)],
    products: [
        .library(
            name: "Event",
            targets: ["Event"]
        )
    ],
    dependencies: [
        .package(path: "../ServerDTO"),
        .package(path: "../Persistence"),
        .package(path: "../Layer"),
        .package(path: "../User"),
        .package(path: "../UseCaseFactory"),
        .package(path: "../Form"),
        .package(path: "../CodableExtensions"),
        .package(path: "../SendableExtensions"),
        .package(path: "../APIRouter"),
        .package(path: "../TestUtilities")
    ],
    targets: [
        .target(
            name: "Event",
            dependencies: [
                "ServerDTO",
                "Persistence",
                "Layer",
                "User",
                "Form",
                "APIRouter",
                "UseCaseFactory",
                "SendableExtensions",
                "CodableExtensions"
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error)
            ]
        ),
        .testTarget(
            name: "EventTests",
            dependencies: [
                "Event",
                "APIRouter",
                "Persistence",
                "TestUtilities"
            ],
            swiftSettings: [
                .treatAllWarnings(as: .error)
            ]
        )
    ]
)
