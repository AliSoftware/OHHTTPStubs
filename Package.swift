// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "OHHTTPStubs",
    products: [
        .library(
            name: "OHHTTPStubs",
            targets: [
                "Core",
            ]
        ),
        .library(
            name: "OHHTTPStubsCore",
            targets: [
                "Core"
            ]
        ),
        .library(
            name: "OHHTTPStubsHTTPMessage",
            targets: [
                "Core",
                "HTTPMessage"
            ]
        ),
        .library(
            name: "OHHTTPStubsSwift",
            targets: [
                "Core",
                "OHHTTPStubsSwift"
            ]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "Core",
            dependencies: []),
        .testTarget(
            name: "CoreTests",
            dependencies: ["Core"]),
        .target(
            name: "HTTPMessage",
            dependencies: ["Core"]),
        .target(
            name: "OHHTTPStubsSwift",
            dependencies: ["Core"]),
        .testTarget(
            name: "OHHTTPStubsSwiftTests",
            dependencies: ["OHHTTPStubsSwift", "Core"]
        )
    ]
)
