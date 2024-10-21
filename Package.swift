// swift-tools-version:5.10

import PackageDescription

let package = Package(
    name: "ECashKit",
    platforms: [
        .iOS(.v14),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "ECashKit",
            targets: ["ECashKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.28.2"),
        .package(url: "https://github.com/sunimp/BitcoinCore.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/sunimp/BitcoinCashKit.git", .upToNextMajor(from: "1.0.0")),
        .package(url: "https://github.com/nicklockwood/SwiftFormat.git", from: "0.54.6"),
    ],
    targets: [
        .target(
            name: "ECashKit",
            dependencies: [
                "BitcoinCore",
                "BitcoinCashKit",
                .product(name: "SwiftProtobuf", package: "swift-protobuf"),
            ]
        ),
    ]
)
