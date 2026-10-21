// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ReStats",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ReStats", targets: ["ReStats"])
    ],
    targets: [
        .executableTarget(
            name: "ReStats",
            path: "Sources/ReStats"
        )
    ]
)
