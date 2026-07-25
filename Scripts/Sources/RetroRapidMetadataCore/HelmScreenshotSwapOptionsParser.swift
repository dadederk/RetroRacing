//
//  HelmScreenshotSwapOptionsParser.swift
//  RetroRacing
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation
import ScriptSupport

public enum HelmScreenshotSwapOptionsParser {
    public static func parse(_ arguments: CLIArguments) throws -> HelmScreenshotSwapOptions {
        try arguments.rejectUnknownFlags(
            allowing: ["--dry-run", "--check"],
            valueFlags: [
                "--helm",
                "--version-id",
                "--app-id",
                "--version",
                "--asc-platform",
                "--platform",
                "--first",
                "--second",
                "--locale",
            ]
        )

        guard let firstRaw = try arguments.value(after: "--first"),
              let firstPosition = Int(firstRaw) else {
            throw MetadataToolError.invalidArguments(
                "--first requires a 1-based screenshot position."
            )
        }
        guard let secondRaw = try arguments.value(after: "--second"),
              let secondPosition = Int(secondRaw) else {
            throw MetadataToolError.invalidArguments(
                "--second requires a 1-based screenshot position."
            )
        }
        guard firstPosition > 0, secondPosition > 0 else {
            throw MetadataToolError.invalidArguments(
                "Screenshot positions must be greater than zero."
            )
        }
        guard firstPosition != secondPosition else {
            throw MetadataToolError.invalidArguments(
                "--first and --second must be different positions."
            )
        }

        let platformRaw = try arguments.value(after: "--platform") ?? HelmScreenshotPlatform.iphone.rawValue
        guard let platform = HelmScreenshotPlatform(rawValue: platformRaw) else {
            throw MetadataToolError.invalidArguments(
                "Unsupported --platform value '\(platformRaw)'. "
                    + "Expected one of: \(HelmScreenshotPlatform.allCases.map(\.rawValue).joined(separator: ", "))."
            )
        }

        let ascPlatform = try arguments.value(after: "--asc-platform") ?? platform.ascPlatformCode
        guard ascPlatform == "IOS" || ascPlatform == "MAC_OS" else {
            throw MetadataToolError.invalidArguments(
                "--asc-platform must be IOS or MAC_OS."
            )
        }

        return HelmScreenshotSwapOptions(
            helmPath: try HelmCLI.resolvePath(from: arguments),
            versionID: try arguments.value(after: "--version-id"),
            appID: try arguments.value(after: "--app-id") ?? HelmScreenshotSwapOptions.defaultAppID,
            versionString: try arguments.value(after: "--version")
                ?? HelmScreenshotSwapOptions.defaultVersion,
            ascPlatformCode: ascPlatform,
            platform: platform,
            firstPosition: firstPosition,
            secondPosition: secondPosition,
            locales: arguments.values(for: "--locale"),
            dryRun: arguments.contains("--dry-run"),
            checkOnly: arguments.contains("--check")
        )
    }
}
