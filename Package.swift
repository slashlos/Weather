// swift-tools-version:5.3
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Weather",
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Weather",
            targets: ["Weather"]),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
		.package(url: "https://github.com/slashlos/fmdb", from: "2.7.7"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Weather",
            dependencies: [],
			path: "Weather",
			publicHeadersPath: "."),
        .testTarget(
            name: "WeatherTests",
            dependencies: ["Weather"]),
    ]
)
