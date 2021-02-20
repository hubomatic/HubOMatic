// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "HubOMatic",
    platforms: [
        .macOS(.v11),
    ],
    products: [
        .library(
            name: "HubOMatic",
            targets: ["HubOMatic"]),
    ],
    dependencies: [
        .package(name: "Sparkle", url: "https://github.com/sparkle-project/Sparkle", from: "1.25.0-rc2"),
    ],
    targets: [
        .target(
            name: "HubOMatic",
            dependencies: ["Sparkle"]),
        .testTarget(
            name: "HubOMaticTests",
            dependencies: ["HubOMatic"]),
    ]
)
