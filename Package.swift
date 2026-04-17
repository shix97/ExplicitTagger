// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "ExplicitTagger",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "ExplicitTagger",
            path: "Sources/ExplicitTagger",
            resources: [
                .process("Resources")
            ]
        )
    ]
)
