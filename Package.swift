// swift-tools-version: 5.6
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "GraphQLDepthLimit",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "GraphQLDepthLimit",
            targets: ["GraphQLDepthLimit"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/GraphQLSwift/GraphQL", from: "2.4.0")
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "GraphQLDepthLimit",
            dependencies: [
                "GraphQL"
            ]),
        .testTarget(
            name: "GraphQLDepthLimitTests",
            dependencies: ["GraphQLDepthLimit"]),
    ]
)
