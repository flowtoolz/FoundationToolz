// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "FoundationToolz",
    products: [
        .library(
            name: "FoundationToolz",
            targets: ["FoundationToolz"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/flowtoolz/SwiftyToolz.git", exact: "0.5.2")
//        .package(path: "../SwiftyToolz")
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
