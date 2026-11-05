// swift-tools-version:5.5
import PackageDescription

let package = Package(
    name: "KoinAntifraud",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "KoinAntifraud", targets: ["KoinFingerprint"])
    ],
    targets: [
        .binaryTarget(name: "KoinFingerprint", path: "KoinFingerprint.xcframework")
    ]
)
