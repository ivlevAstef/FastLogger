// swift-tools-version:5.9
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

