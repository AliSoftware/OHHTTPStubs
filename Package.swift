// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "OHHTTPStubs",
    products: [
        .library(
            name: "OHHTTPStubs",
            targets: [
                "Core",
                "NSURLSession"
            ]
        ),
        .library(
            name: "OHHTTPStubsCore",
            targets: [
                "Core"
            ]
        ),
        .library(
            name: "OHHTTPStubsNSURLSession",
            targets: [
                "Core",
                "NSURLSession"
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
                "NSURLSession",
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
            name: "NSURLSession",
            dependencies: ["Core"]),
        .testTarget(
            name: "NSURLSessionTests",
            dependencies: ["NSURLSession"]),
        .target(
            name: "HTTPMessage",
            dependencies: ["Core"]),
        .target(
            name: "OHHTTPStubsSwift",
            dependencies: ["Core", "NSURLSession"]),
        .testTarget(
            name: "OHHTTPStubsSwiftTests",
            dependencies: ["OHHTTPStubsSwift", "Core"]
        )
    ]
)
