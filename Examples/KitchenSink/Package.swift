// swift-tools-version: 5.6

import PackageDescription

let package = Package(
   name: "KitchenSink",
   platforms: [
       .macOS(.v11)
   ],
   dependencies: [
       .package(path: "../../")
   ],
   targets: [
       .executableTarget(
           name: "KitchenSink",
           dependencies: ["SwiftTUI"]
       )
   ]
)
