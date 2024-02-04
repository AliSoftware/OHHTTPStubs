// swift-tools-version:5.0
import PackageDescription

#if swift(>=5.9)
let platforms: [PackageDescription.SupportedPlatform] = [.macOS(.v10_13), .iOS(.v12), .watchOS(.v4), .tvOS(.v12)]
#elseif swift(>=5.7)
let platforms: [PackageDescription.SupportedPlatform] = [.macOS(.v10_13), .iOS(.v11), .watchOS(.v4), .tvOS(.v11)]
#elseif swift(>=5.0)
let platforms: [PackageDescription.SupportedPlatform] = [.macOS(.v10_10), .iOS(.v9), .watchOS(.v2), .tvOS(.v9)]
#endif

let package = Package(
    name: "OHHTTPStubs",
    platforms: platforms,
    products: [
        .library(
            name: "OHHTTPStubs",
            targets: [
                "OHHTTPStubs",
            ]
        ),
        .library(
            name: "OHHTTPStubsSwift",
            targets: [
                "OHHTTPStubs",
                "OHHTTPStubsSwift"
            ]
        )
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "OHHTTPStubs",
            dependencies: []),
        .testTarget(
            name: "OHHTTPStubsTests",
            dependencies: ["OHHTTPStubs"]),
        .target(
            name: "OHHTTPStubsSwift",
            dependencies: ["OHHTTPStubs"]),
        .testTarget(
            name: "OHHTTPStubsSwiftTests",
            dependencies: ["OHHTTPStubsSwift", "OHHTTPStubs"]
        )
    ]
)
