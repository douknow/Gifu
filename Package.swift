// swift-tools-version:5.0

import PackageDescription

let package = Package(
  name: "Gifu",
  platforms: [.iOS("17.0"), .tvOS(.v11)],
  products: [
    .library(
      name: "Gifu",
      targets: ["Gifu"]),
  ],
  dependencies: [],
  targets: [
    .target(
      name: "Gifu",
      dependencies: []
    ),
  ]
)
