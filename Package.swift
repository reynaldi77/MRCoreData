// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "MRCoreData",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8)
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
