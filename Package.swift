// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "OHHTTPStubs",
    products: [
        .library(
            name: "OHHTTPStubs",
            targets: [
                "Core",
                "NSURLSession",
                "OHPathHelpers"
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
            name: "OHHTTPStubsPathHelpers",
            targets: [
                "OHPathHelpers"
            ]
        ),
        .library(
            name: "OHHTTPStubsSwift",
            targets: [
                "Core",
                "NSURLSession",
                "OHPathHelpers",
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
            name: "OHPathHelpers",
            dependencies: ["Core"]),
        .testTarget(
            name: "OHPathHelpersTests",
            dependencies: ["OHPathHelpers"]),
        .target(
            name: "OHHTTPStubsSwift",
            dependencies: ["Core", "NSURLSession", "OHPathHelpers"]),
        .testTarget(
            name: "OHHTTPStubsSwiftTests",
            dependencies: ["OHHTTPStubsSwift", "Core"]
        )
    ]
)
