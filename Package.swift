// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "KoinFingerprint",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "KoinFingerprint", targets: ["KoinFingerprint"])
    ],
    targets: [
        .binaryTarget(
            name: "KoinFingerprint",
            url: "https://github.com/koinlatam/ios-sdk/releases/download/1.9.0/KoinFingerprint-xcframework.zip",
            checksum: "1790efdad29768fbe82d77ac823e9c031426bba374fe4792aa10b20c0b126dc4"
        )
    ]
)
