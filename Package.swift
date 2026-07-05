// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "TileManager",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "TileManager", targets: ["TileManager"]),
        .executable(name: "TileManagerGeometryTests", targets: ["TileManagerGeometryTests"]),
        .library(name: "TileManagerCore", targets: ["TileManagerCore"])
    ],
    targets: [
        .target(name: "TileManagerCore"),
        .executableTarget(
            name: "TileManager",
            dependencies: ["TileManagerCore"]
        ),
        .executableTarget(
            name: "TileManagerGeometryTests",
            dependencies: ["TileManagerCore"]
        )
    ]
)
