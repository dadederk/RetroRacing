//
//  ReleasePackagingValidator.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation
import ScriptSupport

enum ReleasePackagingValidator {
    private struct Target {
        let platform: String
        let scheme: String
        let destination: String
        let expectedAppName: String
        let embeddedFrameworkRelativePaths: [String]
    }

    static func run(repositoryRoot: URL, check: Bool) throws {
        for target in targets {
            try withTemporaryDerivedData(
                repositoryRoot: repositoryRoot,
                platform: target.platform
            ) { derivedData in
                try ProcessRunner.run(
                    ProcessCommand(
                        executable: "/usr/bin/xcodebuild",
                        arguments: [
                            "build", "-quiet",
                            "-project", "RetroRacing/RetroRacing.xcodeproj",
                            "-scheme", target.scheme,
                            "-configuration", "Release",
                            "-destination", target.destination,
                            "-derivedDataPath", derivedData.path,
                            "CODE_SIGNING_ALLOWED=NO",
                        ],
                        currentDirectory: repositoryRoot
                    )
                )
                let appURL = try builtAppURL(in: derivedData, named: target.expectedAppName)
                print("  \(target.platform) package: \(try directorySize(appURL)) bytes")
                if check {
                    try validate(appURL: appURL, target: target)
                }
            }
        }
    }

    static func withTemporaryDerivedData<Result>(
        repositoryRoot: URL,
        platform: String,
        operation: (URL) throws -> Result
    ) rethrows -> Result {
        let runIdentifier = ProcessInfo.processInfo.globallyUniqueString
            .replacingOccurrences(of: "/", with: "-")
            .replacingOccurrences(of: ":", with: "-")
        let derivedData = repositoryRoot.appending(
            path: ".build/asset-audit/release-\(platform)-\(runIdentifier)"
        )
        defer { try? FileManager.default.removeItem(at: derivedData) }
        return try operation(derivedData)
    }

    private static func validate(appURL: URL, target: Target) throws {
        let embeddedFramework = target.embeddedFrameworkRelativePaths
            .map { appURL.appending(path: $0) }
            .first { FileManager.default.fileExists(atPath: $0.path) }
        guard embeddedFramework != nil else {
            throw AssetAuditError.validationFailed([
                "\(target.scheme) links RetroRacingShared.framework but did not embed it in \(appURL.lastPathComponent)",
            ])
        }
        let issues = archiveIssues(inReleaseProduct: appURL)
        if issues.isEmpty == false {
            throw AssetAuditError.validationFailed(
                issues.map { "\(target.scheme) \($0)" }
            )
        }
    }

    static func archiveIssues(inReleaseProduct productURL: URL) -> [String] {
        guard let enumerator = FileManager.default.enumerator(
            at: productURL,
            includingPropertiesForKeys: nil
        ) else { return [] }
        let forbiddenNames = Set(["AssetSources", "DiscardedAssets"])
        return Set(
            enumerator.compactMap { ($0 as? URL)?.lastPathComponent }
                .filter { forbiddenNames.contains($0) }
        ).sorted().map { "embeds non-target archive '\($0)'" }
    }

    private static func builtAppURL(in derivedData: URL, named expectedAppName: String) throws -> URL {
        let products = derivedData.appending(path: "Build/Products")
        guard let enumerator = FileManager.default.enumerator(at: products, includingPropertiesForKeys: nil) else {
            throw AssetAuditError.validationFailed(["No built products found at \(products.path)"])
        }
        for case let url as URL in enumerator where url.lastPathComponent == expectedAppName {
            return url
        }
        throw AssetAuditError.validationFailed(["No \(expectedAppName) product found at \(products.path)"])
    }

    private static func directorySize(_ url: URL) throws -> Int {
        guard let enumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: [.fileSizeKey]
        ) else { return 0 }
        return enumerator.reduce(into: 0) { total, item in
            guard let fileURL = item as? URL else { return }
            total += (try? fileURL.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
        }
    }

    private static let targets = [
        Target(platform: "ios", scheme: "RetroRacingUniversal", destination: "generic/platform=iOS", expectedAppName: "RetroRacingUniversal.app", embeddedFrameworkRelativePaths: ["Frameworks/RetroRacingShared.framework"]),
        Target(platform: "watch", scheme: "RetroRacingWatchOS", destination: "generic/platform=watchOS", expectedAppName: "RetroRacingWatchOS.app", embeddedFrameworkRelativePaths: ["Frameworks/RetroRacingShared.framework"]),
        Target(platform: "mac", scheme: "RetroRacingUniversal", destination: "generic/platform=macOS", expectedAppName: "RetroRapid!.app", embeddedFrameworkRelativePaths: ["Contents/Frameworks/RetroRacingShared.framework"]),
        Target(platform: "tv", scheme: "RetroRacingTvOS", destination: "generic/platform=tvOS", expectedAppName: "RetroRacingTvOS.app", embeddedFrameworkRelativePaths: ["Frameworks/RetroRacingShared.framework"]),
        Target(platform: "vision", scheme: "RetroRacingVisionOS", destination: "generic/platform=visionOS", expectedAppName: "RetroRacingVisionOS.app", embeddedFrameworkRelativePaths: ["Frameworks/RetroRacingShared.framework"]),
    ]
}
