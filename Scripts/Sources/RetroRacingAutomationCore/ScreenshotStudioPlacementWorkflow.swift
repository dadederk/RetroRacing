//
//  ScreenshotStudioPlacementWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import ScriptSupport

public struct ScreenshotStudioPlacementOptions: Sendable, Equatable {
    public let stagingDirectory: URL
    public let platform: String
    public let locales: [String]
    public let slideIndexes: [Int]
    public let dryRun: Bool
    public let checkOnly: Bool

    public init(
        stagingDirectory: URL,
        platform: String = "iphone",
        locales: [String] = ScreenshotStudioWorkflow.locales,
        slideIndexes: [Int] = Array(0..<ScreenshotStudioWorkflow.slideCount),
        dryRun: Bool = false,
        checkOnly: Bool = false
    ) {
        self.stagingDirectory = stagingDirectory
        self.platform = platform
        self.locales = locales
        self.slideIndexes = slideIndexes
        self.dryRun = dryRun
        self.checkOnly = checkOnly
    }
}

public struct ScreenshotStudioPlacementResult: Sendable, Equatable {
    public let installed: [String]
    public let skipped: [String]
    public let missing: [String]
}

public enum ScreenshotStudioPlacementWorkflow {
    public static func stagedFileName(locale: String, slideIndex: Int, fileExtension: String) -> String {
        "\(locale)_\(slideIndex)\(fileExtension)"
    }

    public static func parseStagedFileName(
        _ fileName: String,
        fileExtension: String,
        platform: String = "iphone"
    ) -> (locale: String, slideIndex: Int)? {
        guard fileName.hasSuffix(fileExtension) else { return nil }
        let stem = String(fileName.dropLast(fileExtension.count))
        guard let separatorIndex = stem.lastIndex(of: "_") else { return nil }
        let locale = String(stem[..<separatorIndex])
        let indexString = String(stem[stem.index(after: separatorIndex)...])
        guard let slideIndex = Int(indexString) else { return nil }
        let allowedLocales = ScreenshotStudioWorkflow.locales
        guard allowedLocales.contains(locale) else { return nil }
        guard (0..<ScreenshotStudioWorkflow.slideCount(for: platform)).contains(slideIndex) else { return nil }
        return (locale, slideIndex)
    }

    public static func destinationURL(
        repositoryRoot: URL,
        platform: String,
        locale: String,
        slideIndex: Int
    ) throws -> URL {
        guard let fileExtension = ScreenshotStudioWorkflow.imageExtension(for: platform) else {
            throw ScreenshotStudioError.unsupportedPlatform(platform)
        }
        return repositoryRoot
            .appending(path: "AppStore/RetroRapid.screenshotstudio")
            .appending(path: platform)
            .appending(path: "images")
            .appending(path: stagedFileName(locale: locale, slideIndex: slideIndex, fileExtension: fileExtension))
    }

    public static func installTarget(
        repositoryRoot: URL,
        options: ScreenshotStudioPlacementOptions,
        target: ScreenshotCaptureTarget
    ) throws -> ScreenshotStudioPlacementResult {
        let scopedOptions = ScreenshotStudioPlacementOptions(
            stagingDirectory: options.stagingDirectory,
            platform: options.platform,
            locales: [target.locale],
            slideIndexes: [target.slideIndex],
            dryRun: options.dryRun,
            checkOnly: options.checkOnly
        )
        return try install(repositoryRoot: repositoryRoot, options: scopedOptions)
    }

    public static func install(
        repositoryRoot: URL,
        options: ScreenshotStudioPlacementOptions
    ) throws -> ScreenshotStudioPlacementResult {
        guard let fileExtension = ScreenshotStudioWorkflow.imageExtension(for: options.platform) else {
            throw ScreenshotStudioError.unsupportedPlatform(options.platform)
        }

        var installed = [String]()
        var skipped = [String]()
        var missing = [String]()

        for locale in options.locales {
            for slideIndex in options.slideIndexes {
                let fileName = stagedFileName(
                    locale: locale,
                    slideIndex: slideIndex,
                    fileExtension: fileExtension
                )
                let sourceURL = options.stagingDirectory.appending(path: fileName)
                let destinationURL = try destinationURL(
                    repositoryRoot: repositoryRoot,
                    platform: options.platform,
                    locale: locale,
                    slideIndex: slideIndex
                )

                guard FileManager.default.fileExists(atPath: sourceURL.path) else {
                    missing.append(fileName)
                    continue
                }

                if options.dryRun || options.checkOnly {
                    installed.append("\(fileName) -> \(destinationURL.lastPathComponent)")
                    continue
                }

                let sourceData = try Data(contentsOf: sourceURL)
                try FileManager.default.createDirectory(
                    at: destinationURL.deletingLastPathComponent(),
                    withIntermediateDirectories: true
                )
                try sourceData.write(to: destinationURL, options: .atomic)
                installed.append(fileName)
            }
        }

        if options.checkOnly == false, options.dryRun == false, installed.isEmpty == false {
            try refreshManifest(
                repositoryRoot: repositoryRoot,
                platform: options.platform
            )
        }

        return ScreenshotStudioPlacementResult(
            installed: installed,
            skipped: skipped,
            missing: missing
        )
    }

    public static func refreshManifest(repositoryRoot: URL, platform: String) throws {
        guard let fileExtension = ScreenshotStudioWorkflow.imageExtension(for: platform) else {
            throw ScreenshotStudioError.unsupportedPlatform(platform)
        }
        let imagesDirectory = repositoryRoot
            .appending(path: "AppStore/RetroRapid.screenshotstudio")
            .appending(path: platform)
            .appending(path: "images")
        let manifest = try ScreenshotStudioWorkflow.contentsManifest(
            platform: platform,
            slideCount: ScreenshotStudioWorkflow.slideCount
        )
        let manifestURL = imagesDirectory.appending(path: "contents.json")
        let data = try JSONSerialization.data(withJSONObject: manifest, options: [.sortedKeys, .prettyPrinted])
        try FileManager.default.createDirectory(
            at: imagesDirectory,
            withIntermediateDirectories: true
        )
        try data.write(to: manifestURL, options: .atomic)
        _ = fileExtension
    }

    public static func missingStudioImages(
        repositoryRoot: URL,
        platform: String,
        locales: [String] = ScreenshotStudioWorkflow.locales,
        slideIndexes: [Int] = Array(0..<ScreenshotStudioWorkflow.slideCount)
    ) throws -> [String] {
        guard let fileExtension = ScreenshotStudioWorkflow.imageExtension(for: platform) else {
            throw ScreenshotStudioError.unsupportedPlatform(platform)
        }
        return try locales.flatMap { locale in
            try slideIndexes.compactMap { slideIndex -> String? in
                let url = try destinationURL(
                    repositoryRoot: repositoryRoot,
                    platform: platform,
                    locale: locale,
                    slideIndex: slideIndex
                )
                guard FileManager.default.fileExists(atPath: url.path) else {
                    return stagedFileName(
                        locale: locale,
                        slideIndex: slideIndex,
                        fileExtension: fileExtension
                    )
                }
                return nil
            }
        }
    }
}

extension ScreenshotStudioWorkflow {
    public static func imageExtension(for platform: String) -> String? {
        switch platform {
        case "iphone", "ipad", "appleWatch":
            return ".jpeg"
        case "mac":
            return ".png"
        default:
            return nil
        }
    }
}
