// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MapboxGeocoder",
    platforms: [
        .macOS(.v10_14), .iOS(.v12), .watchOS(.v5), .tvOS(.v12)
    ],
    products: [
        // Products define the executables and libraries produced by a package, and make them visible to other packages.
        .library(
            name: "MapboxGeocoder",
            targets: ["MapboxGeocoder"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(name: "OHHTTPStubs", url: "https://github.com/AliSoftware/OHHTTPStubs.git", from: "9.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends on.
        .target(
            name: "MapboxGeocoder",
            exclude: [
                "Info.plist",
                "MBPlacemarkPrecision.h",
                "MBPlacemarkPrecision.m",
                "MBPlacemarkScope.h",
            ]),
        .testTarget(
            name: "MapboxGeocoderTests",
            dependencies: [
                "MapboxGeocoder",
                .product(name: "OHHTTPStubsSwift", package: "OHHTTPStubs"),
            ],
            exclude: [
                "Info.plist",
                "BridgingTests.m",
            ],
            resources: [
                .process("fixtures"),
            ]),
    ]
)
