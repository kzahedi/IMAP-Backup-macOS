// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "IMAP-Backup-macOS",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .executable(name: "IMAP-Backup-macOS", targets: ["IMAP-Backup-macOS"])
    ],
    dependencies: [
        .package(url: "https://github.com/krzyzanowskim/CryptoSwift", from: "1.8.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.65.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl", from: "2.26.0"),
        .package(url: "https://github.com/apple/swift-collections", from: "1.1.0"),
        .package(url: "https://github.com/apple/swift-log", from: "1.6.0")
    ],
    targets: [
        .executableTarget(
            name: "IMAP-Backup-macOS",
            dependencies: [
                "CryptoSwift",
                .product(name: "NIO", package: "swift-nio"),
                .product(name: "NIOSSL", package: "swift-nio-ssl"),
                .product(name: "Collections", package: "swift-collections"),
                .product(name: "Logging", package: "swift-log")
            ],
            path: "IMAP Backup/Sources",
            swiftSettings: [
                .enableExperimentalFeature("StrictConcurrency")
            ]
        )
    ]
)