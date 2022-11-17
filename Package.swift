// swift-tools-version:5.6

import PackageDescription

let package = Package(
    name: "FoundationToolz",
    platforms: [.iOS(.v12), .tvOS(.v12), .macOS(.v10_14), .watchOS(.v5)],
    products: [
        .library(
            name: "FoundationToolz",
            targets: ["FoundationToolz"]
        ),
    ],
    dependencies: [
        .package(
            url: "https://github.com/flowtoolz/SwiftyToolz.git",
            exact: "0.2.0"
        )
    ],
    targets: [
        .target(
            name: "FoundationToolz",
            dependencies: ["SwiftyToolz"],
            path: "Code"
        ),
        .testTarget(
            name: "FoundationToolzTests",
            dependencies: ["FoundationToolz", "SwiftyToolz"],
            path: "Tests"
        ),
    ]
)
