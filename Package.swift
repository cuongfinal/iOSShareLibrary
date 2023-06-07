// swift-tools-version:5.3

import PackageDescription

let package = Package(
    name: "iOSShareLibrary",
    platforms: [
        .iOS(.v14)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "iOSShareLibrary",
            targets: ["iOSShareLibrary"])
    ],
    dependencies: [
        .package(name: "Firebase", url: "https://github.com/firebase/firebase-ios-sdk.git", from: "8.13.0"),
        .package(name: "GoogleMaps", url: "https://github.com/mthole/GoogleMaps-SP.git", from: "5.0.0"),
        .package(name: "Shake", url: "https://github.com/shakebugs/shake-ios", from: "15.0.2"),
        .package(url: "https://github.com/jasudev/AxisTooltip.git", .branch("main")),
        .package(name: "Facebook", url: "https://github.com/facebook/facebook-ios-sdk", .upToNextMajor(from: "14.0.0")),
        .package(name: "CleverTap", url: "https://github.com/CleverTap/clevertap-ios-sdk.git", .upToNextMajor(from: "4.1.1")),
        .package(name: "Lottie", url: "https://github.com/airbnb/lottie-ios.git", from: "3.2.3"),
        .package(url: "https://github.com/OrderTigerDev/iOSRepositories.git", .branch("master"))
    ],
    targets: [
        .target(name: "iOSShareLibrary", dependencies: ["Shake", "Lottie", "iOSRepositories",
                                                    .product(name: "CleverTapSDK", package: "CleverTap"),
                                                    .product(name: "FacebookCore", package: "Facebook"),
                                                    .product(name: "GooglePlaces", package: "GoogleMaps"),
                                                    .product(name: "GoogleMaps", package: "GoogleMaps"),
                                                    .product(name: "FirebaseAnalytics", package: "Firebase"),
                                                    .product(name: "FirebaseCrashlytics", package: "Firebase"),
                                                    .product(name: "FirebaseDynamicLinks", package: "Firebase"),
                                                    .product(name: "AxisTooltip", package: "AxisTooltip")
        ], path: "Sources/iOSShareLibrary"),
        .testTarget(
            name: "iOSShareLibraryTests",
            dependencies: ["iOSShareLibrary"],
            path: "Tests"),
    ]
)
