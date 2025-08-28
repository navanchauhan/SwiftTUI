// swift-tools-version: 6.0

import PackageDescription

let package = Package(
   name: "SwiftTUI",
   platforms: [
       .macOS(.v11)
   ],
   products: [
       .library(
           name: "SwiftTUI",
           targets: ["SwiftTUI"]),
   ],
   dependencies: [
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0"),
        .package(url: "https://github.com/OpenCombine/OpenCombine.git", from: "0.14.0")
   ],
   targets: [
       .target(
           name: "SwiftTUI",
           dependencies: [
               .product(name: "OpenCombine", package: "OpenCombine")
           ]),
       .testTarget(
           name: "SwiftTUITests",
           dependencies: ["SwiftTUI"]),
   ]
)
