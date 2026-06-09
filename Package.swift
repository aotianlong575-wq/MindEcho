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
        .target(
            name: "MindEchoCore",
            dependencies: ["Alamofire"],
            path: "src/MindEcho/Services"
        ),
        .executableTarget(
            name: "MindEchoApp",
            dependencies: ["MindEchoCore", "Kingfisher"],
            path: "src/MindEcho"
        ),
        .testTarget(
            name: "MindEchoTests",
            dependencies: ["MindEchoCore"],
            path: "tests/MindEchoTests"
        )
    ]
)
