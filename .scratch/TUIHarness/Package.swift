// swift-tools-version: 6.0

import PackageDescription

let package = Package(
   name: "TUIHarness",
   platforms: [
       .macOS(.v11)
   ],
   products: [
       .executable(name: "TUIHarness", targets: ["TUIHarness"])
   ],
   dependencies: [
       .package(path: "../../")
   ],
   targets: [
       .executableTarget(
           name: "TUIHarness",
           dependencies: ["SwiftTUI"]
       )
   ]
)
