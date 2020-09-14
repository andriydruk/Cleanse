// swift-tools-version:5.0

import PackageDescription

let package = Package(
    name: "Cleanse",
    products: [
        .library(name: "Cleanse", targets: ["Cleanse"]),
    ],
    dependencies: [],
    targets: [
        .target(name: "Cleanse", dependencies: [], path: "Cleanse"),
    ]
)

