// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "ScreenRuler",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ScreenRuler",
            path: "Sources/ScreenRuler",
            swiftSettings: [.swiftLanguageMode(.v5)]
        )
    ]
)
