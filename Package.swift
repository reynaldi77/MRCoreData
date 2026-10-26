// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MRCoreData",
    platforms: [
        .iOS(.v12),
        .macOS(.v10_13),
        .tvOS(.v12),
        .watchOS(.v4)
    ],
    products: [
        .library(
            name: "MRCoreData",
            targets: ["MRCoreData"]
        ),
    ],
    targets: [
        .target(
            name: "MRCoreData",
            path: ".",
            sources: ["Core", "Extensions"]
        ),
    ]
)
