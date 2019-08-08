// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "OHHTTPStubs",
    products: [
        .library(
            name: "OHHTTPStubs",
            targets: [
                "Core",
                "NSURLSession",
                "JSON",
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
            name: "OHHTTPStubsJSON",
            targets: [
                "Core",
                "JSON"
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
                "JSON",
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
            dependencies: ["NSURLSession", "JSON"]),
        .target(
            name: "JSON",
            dependencies: ["Core"]),
        .testTarget(
            name: "JSONTests",
            dependencies: ["JSON"]),
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
            dependencies: ["Core", "NSURLSession", "JSON", "OHPathHelpers"])
    ]
)





