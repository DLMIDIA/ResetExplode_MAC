// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ResetExplode",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ResetExplode", targets: ["ResetExplode"])
    ],
    targets: [
        .executableTarget(
            name: "ResetExplode",
            path: "Sources/ResetExplode"
        )
    ]
)
