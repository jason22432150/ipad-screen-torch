// swift-tools-version: 5.9
import PackageDescription

// Portable core tests only; this is not the iOS application build.
let package = Package(
    name: "TorchCoreCheck",
    platforms: [.macOS(.v12)],
    targets: [
        .target(name: "iPadScreenTorch", path: "iPadScreenTorch/Core"),
        .testTarget(name: "iPadScreenTorchTests", dependencies: ["iPadScreenTorch"], path: "iPadScreenTorchTests")
    ]
)
