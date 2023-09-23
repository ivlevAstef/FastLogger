// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "FastLogger",
    products: [
        .library(name: "FastLogger", targets: ["FastLogger"])
    ],
    targets: [
        .target(name: "FastLogger", path: "./Sources")
    ]
)

