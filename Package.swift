// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "HubOMatic",
    products: [
        .library(
            name: "HubOMatic",
            targets: ["HubOMatic"]),
    ],
    dependencies: [
        .package(name: "MiscKit", url: "https://github.com/glimpseio/MiscKit", .branch("main")),
    ],
    targets: [
        .target(
            name: "HubOMatic",
            dependencies: ["MiscKit"]),
        .testTarget(
            name: "HubOMaticTests",
            dependencies: ["HubOMatic"]),
    ]
)
