// swift-tools-version:5.7

import PackageDescription

let package = Package(
    name: "PianoRollEditor",
    platforms: [
        .macOS(.v10_15),
        .iOS(.v16)
    ],
    products: [
        .library(name: "PianoRollEditor", targets: ["PianoRollEditor"])
    ],
    dependencies: [
        .package(url: "https://github.com/AudioKit/Keyboard", branch: "main"),
        .package(url: "https://github.com/AudioKit/PianoRoll", from: "1.0.5"),
        .package(url: "https://github.com/edudnyk/SolidScroll", from: "0.0.1"),
        .package(url: "https://github.com/pointfreeco/swift-composable-architecture", from: "0.44.0"),
        .package(url: "https://github.com/AudioKit/Tonic", from: "1.0.6"),
    ],
    targets: [
        .target(
            name: "PianoRollEditor",
            dependencies: [
                "Keyboard",
                "SolidScroll",
                .product(name: "ComposableArchitecture", package: "swift-composable-architecture"),
                .product(name: "PianoRoll", package: "PianoRoll"),
            ]
        )
    ]
)
