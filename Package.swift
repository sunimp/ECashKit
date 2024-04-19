// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "ECashKit",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "ECashKit",
            targets: ["ECashKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/horizontalsystems/BitcoinCore.Swift.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/horizontalsystems/BitcoinCashKit.Swift.git", .upToNextMajor(from: "3.0.0")),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.6.0"),
    ],
    targets: [
        .target(
            name: "ECashKit",
            dependencies: [
                .product(name: "BitcoinCore", package: "BitcoinCore.Swift"),
                .product(name: "BitcoinCashKit", package: "BitcoinCashKit.Swift"),
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ]
        ),
    ]
)
