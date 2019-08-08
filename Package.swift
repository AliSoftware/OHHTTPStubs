// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "OHHTTPStubs",
    products: [
        .library(
            name: "OHHTTPStubs",
            targets: [
                "OHHTTPStubsCore",
            ]
        ),
        .library(
            name: "OHHTTPStubsSwift",
            targets: [
                "OHHTTPStubsCore",
                "OHHTTPStubsSwift"
            ]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "OHHTTPStubsCore",
            dependencies: []),
        .testTarget(
            name: "OHHTTPStubsCoreTests",
            dependencies: ["OHHTTPStubsCore"]),
        .target(
            name: "OHHTTPStubsSwift",
            dependencies: ["OHHTTPStubsCore"]),
        .testTarget(
            name: "OHHTTPStubsSwiftTests",
            dependencies: ["OHHTTPStubsSwift", "OHHTTPStubsCore"]
        )
    ]
)
