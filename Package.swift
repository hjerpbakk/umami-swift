// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Umami",
    platforms: [.iOS(.v15), .macOS(.v12)],
    products: [
        .library(name: "Umami", targets: ["Umami"]),
    ],
    targets: [
        .target(name: "Umami"),
        .testTarget(name: "UmamiTests", dependencies: ["Umami"]),
    ]
)
