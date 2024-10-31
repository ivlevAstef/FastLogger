// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "FastLogger",
    platforms: [.iOS(.v13), .watchOS(.v6), .tvOS(.v13), .macOS(.v10_14)],
    products: [
        .library(name: "FastLogger", targets: ["FastLogger"])
    ],
    targets: [
        .target(name: "FastLogger", path: "./Sources")
    ]
)
