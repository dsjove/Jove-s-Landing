// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "Infrastructure",
    platforms: [
        .iOS(.v17),
        .watchOS(.v10),
    ],
    products: [
        .library(
            name: "Infrastructure",
            targets: ["Infrastructure"]),
    ],
    dependencies: [
        .package(path: "../../BLEByJove"),
        .package(path: "../../SBJKit"),
    ],
    targets: [
        .target(
            name: "Infrastructure",
            dependencies: ["BLEByJove", "SBJKit"]),
        .testTarget(
            name: "InfrastructureTests",
            dependencies: ["Infrastructure"]),
    ]
)
