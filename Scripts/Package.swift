// swift-tools-version: 6.0
//
//  Package.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import PackageDescription

let package = Package(
    name: "RetroRacingScripts",
    platforms: [.macOS(.v15)],
    products: [
        .library(name: "ScriptSupport", targets: ["ScriptSupport"]),
        .library(name: "RetroRapidMetadataCore", targets: ["RetroRapidMetadataCore"]),
        .library(name: "RetroRacingAutomationCore", targets: ["RetroRacingAutomationCore"]),
        .executable(name: "run-tests", targets: ["RunTests"]),
        .executable(name: "check-documentation", targets: ["CheckDocumentation"]),
        .executable(name: "generate-road-dash-masks", targets: ["GenerateRoadDashMasks"]),
        .executable(
            name: "sync-screenshot-studio-localizations",
            targets: ["SyncScreenshotStudioLocalizations"]
        ),
        .executable(name: "generate-metadata-docs", targets: ["GenerateMetadataDocs"]),
        .executable(name: "apply-retrorapid-metadata", targets: ["ApplyRetroRapidMetadata"]),
        .executable(name: "submit-testflight-build", targets: ["SubmitTestFlightBuild"]),
    ],
    targets: [
        .target(name: "ScriptSupport"),
        .target(
            name: "RetroRapidMetadataCore",
            dependencies: ["ScriptSupport"]
        ),
        .target(
            name: "RetroRacingAutomationCore",
            dependencies: ["ScriptSupport", "RetroRapidMetadataCore"]
        ),
        .executableTarget(
            name: "CheckDocumentation",
            dependencies: ["RetroRacingAutomationCore"]
        ),
        .executableTarget(
            name: "RunTests",
            dependencies: ["RetroRacingAutomationCore"]
        ),
        .executableTarget(
            name: "GenerateRoadDashMasks",
            dependencies: ["RetroRacingAutomationCore"]
        ),
        .executableTarget(
            name: "SyncScreenshotStudioLocalizations",
            dependencies: ["RetroRacingAutomationCore"]
        ),
        .executableTarget(
            name: "GenerateMetadataDocs",
            dependencies: ["RetroRapidMetadataCore"]
        ),
        .executableTarget(
            name: "ApplyRetroRapidMetadata",
            dependencies: ["RetroRapidMetadataCore", "ScriptSupport"]
        ),
        .executableTarget(
            name: "SubmitTestFlightBuild",
            dependencies: ["RetroRacingAutomationCore", "ScriptSupport"]
        ),
        .testTarget(
            name: "ScriptSupportTests",
            dependencies: ["ScriptSupport"]
        ),
        .testTarget(
            name: "RetroRacingAutomationCoreTests",
            dependencies: ["RetroRacingAutomationCore"]
        ),
        .testTarget(
            name: "RetroRapidMetadataCoreTests",
            dependencies: ["RetroRapidMetadataCore"]
        ),
    ]
)
