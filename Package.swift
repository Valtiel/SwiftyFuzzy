// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftyFuzzy",
    platforms: [
        .macOS(.v13),
        .iOS(.v16),
    ],
    products: [
        .library(
            name: "SwiftyFuzzy",
            targets: ["SwiftyFuzzy"]
        ),
        .executable(
            name: "SwiftyFuzzyDemo",
            targets: ["SwiftyFuzzyDemo"]
        ),
    ],
    targets: [
        .target(
            name: "SwiftyFuzzy"
        ),
        .executableTarget(
            name: "SwiftyFuzzyDemo",
            dependencies: ["SwiftyFuzzy"]
        ),
        .testTarget(
            name: "SwiftyFuzzyTests",
            dependencies: ["SwiftyFuzzy"]
        ),
    ]
)
