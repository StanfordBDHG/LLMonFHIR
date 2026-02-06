// swift-tools-version: 6.2
//
// This source file is part of the Stanford LLM on FHIR project
//
// SPDX-FileCopyrightText: 2026 Stanford University
//
// SPDX-License-Identifier: MIT
//

import PackageDescription


let package = Package(
    name: "LLMonFHIRShared",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v18),
        .macOS(.v15)
    ],
    products: [
        .library(name: "LLMonFHIRShared", targets: ["LLMonFHIRShared"]),
        .library(name: "LLMonFHIRStudyDefinitions", targets: ["LLMonFHIRStudyDefinitions"]),
        .executable(name: "LLMonFHIRCLI", targets: ["LLMonFHIRCLI"])
    ],
    dependencies: [
        .package(url: "https://github.com/StanfordSpezi/SpeziFoundation.git", from: "2.7.2"),
        .package(url: "https://github.com/apple/FHIRModels.git", .upToNextMajor(from: "0.7.0")),
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.7.0"),
        .package(url: "https://github.com/StanfordSpezi/SpeziLLM.git", revision: "1c4edeb3fb9f8256758d60e878ad17acb40c68fb"),
        .package(url: "https://github.com/StanfordSpezi/SpeziStorage.git", from: "2.1.3"),
        .package(url: "https://github.com/StanfordSpezi/SpeziFHIR.git", from: "0.10.0")
    ],
    targets: [
        .target(
            name: "LLMonFHIRShared",
            dependencies: [
                .product(name: "SpeziFoundation", package: "SpeziFoundation"),
                .product(name: "ModelsR4", package: "FHIRModels"),
                .product(name: "SpeziLLM", package: "SpeziLLM"),
                .product(name: "SpeziLLMOpenAI", package: "SpeziLLM"),
                .product(name: "SpeziLocalStorage", package: "SpeziStorage"),
                .product(name: "SpeziFHIR", package: "SpeziFHIR")
            ],
            resources: [
                .copy("Resources/Synthetic Patients")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault")
            ]
        ),
        .target(
            name: "LLMonFHIRStudyDefinitions",
            dependencies: [
                "LLMonFHIRShared",
                .product(name: "ModelsR4", package: "FHIRModels")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny"),
                .enableUpcomingFeature("InternalImportsByDefault")
            ]
        ),
        .executableTarget(
            name: "LLMonFHIRCLI",
            dependencies: [
                "LLMonFHIRShared",
                "LLMonFHIRStudyDefinitions",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            swiftSettings: [
                .enableUpcomingFeature("ExistentialAny")
            ]
        ),
        .testTarget(
            name: "LLMonFHIRSharedTests",
            dependencies: ["LLMonFHIRShared", "LLMonFHIRStudyDefinitions"],
            resources: [.process("Resources")]
        )
    ]
)
