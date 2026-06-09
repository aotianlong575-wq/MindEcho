// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MindEcho",
    platforms: [
        .iOS(.v17),
        .macOS(.v14),
        .visionOS(.v1)
    ],
    products: [
        .library(
            name: "MindEchoCore",
            targets: ["MindEchoCore"]
        ),
        .executable(
            name: "MindEchoApp",
            targets: ["MindEchoApp"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Alamofire/Alamofire.git", from: "5.8.0"),
        .package(url: "https://github.com/onevcat/Kingfisher.git", from: "7.10.0"),
    ],
    targets: [
        // Core 共享层 — Models + Services（可在 macOS CI 上编译测试）
        .target(
            name: "MindEchoCore",
            dependencies: [],
            path: "src/Core"
        ),
        // App 层 — UI 视图（需要 Xcode + iOS/visionOS SDK）
        .executableTarget(
            name: "MindEchoApp",
            dependencies: [
                "MindEchoCore",
            ],
            path: "src/App"
        ),
        // 测试 — 仅依赖 Core 层（无需 iOS SDK）
        .testTarget(
            name: "MindEchoTests",
            dependencies: ["MindEchoCore"],
            path: "tests/MindEchoTests"
        )
    ]
)
