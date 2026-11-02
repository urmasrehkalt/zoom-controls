// swift-tools-version: 5.9
import PackageDescription
let package = Package(name: "Zooom", platforms: [.macOS(.v13)], products: [
    .executable(name: "Zooom", targets: ["Zooom"])
], targets: [
    .target(name: "ZooomCore"),
    .executableTarget(name: "Zooom", dependencies: ["ZooomCore"]),
    .executableTarget(name: "ZooomCoreTests", dependencies: ["ZooomCore"], path: "Tests/ZooomCoreTests")
])
