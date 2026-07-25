//
//  HelmScreenshotVersionResolver.swift
//  RetroRacing
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation

public enum HelmScreenshotVersionResolver {
    private static let preferredStates = [
        "PREPARE_FOR_SUBMISSION",
        "WAITING_FOR_REVIEW",
        "IN_REVIEW",
        "READY_FOR_SALE",
    ]

    public static func resolveVersionID(
        helmPath: String,
        appID: String,
        versionString: String,
        ascPlatformCode: String
    ) throws -> String {
        let output = try HelmCLI.run(
            helmPath: helmPath,
            arguments: ["apps", appID, "versions", "--agent"]
        )
        guard let data = output.data(using: .utf8) else {
            throw MetadataToolError.helmFailed("Helm versions output was not UTF-8.")
        }

        let versions = try JSONDecoder().decode([HelmAppVersionSummary].self, from: data)
        let candidates = versions.filter {
            $0.platform == ascPlatformCode && $0.versionString == versionString
        }

        guard candidates.isEmpty == false else {
            throw MetadataToolError.helmFailed(
                "No App Store version \(versionString) found for platform \(ascPlatformCode)."
            )
        }

        for state in preferredStates {
            if let match = candidates.first(where: { $0.state == state }) {
                return match.id
            }
        }

        guard let fallback = candidates.first else {
            throw MetadataToolError.helmFailed(
                "Could not resolve a version ID for \(versionString) on \(ascPlatformCode)."
            )
        }
        return fallback.id
    }
}
