// swift-tools-version:5.10

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
        .package(url: "https://github.com/sunimp/BitcoinCore.Swift.git", .upToNextMajor(from: "3.0.2")),
        .package(url: "https://github.com/sunimp/BitcoinCashKit.Swift.git", .upToNextMajor(from: "3.0.2")),
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.27.0"),
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
