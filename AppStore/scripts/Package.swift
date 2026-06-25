// swift-tools-version: 6.0
//
//  Package.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import PackageDescription

let package = Package(
    name: "RetroRapidMetadataTools",
    platforms: [.macOS(.v15)],
    products: [
        .library(
            name: "RetroRapidMetadataCore",
            targets: ["RetroRapidMetadataCore"]
        ),
        .executable(
            name: "generate-metadata-docs",
            targets: ["GenerateMetadataDocs"]
        ),
        .executable(
            name: "apply-retrorapid-metadata",
            targets: ["ApplyRetroRapidMetadata"]
        ),
    ],
    targets: [
        .target(name: "RetroRapidMetadataCore"),
        .executableTarget(
            name: "GenerateMetadataDocs",
            dependencies: ["RetroRapidMetadataCore"]
        ),
        .executableTarget(
            name: "ApplyRetroRapidMetadata",
            dependencies: ["RetroRapidMetadataCore"]
        ),
        .testTarget(
            name: "RetroRapidMetadataCoreTests",
            dependencies: ["RetroRapidMetadataCore"]
        ),
    ]
)
