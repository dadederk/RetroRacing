//
//  HelmMetadataWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import ScriptSupport

public struct MetadataApplyOptions: Sendable {
    public let helmPath: String
    public let keywordsOnly: Bool
    public let includeAppInfo: Bool
    public let dryRun: Bool

    public init(
        helmPath: String,
        keywordsOnly: Bool,
        includeAppInfo: Bool,
        dryRun: Bool
    ) {
        self.helmPath = helmPath
        self.keywordsOnly = keywordsOnly
        self.includeAppInfo = includeAppInfo
        self.dryRun = dryRun
    }
}

public enum HelmMetadataWorkflow {
    public static func applyCatalog(
        _ catalog: MetadataCatalog,
        options: MetadataApplyOptions
    ) throws {
        if options.dryRun {
            printApplyPlan(catalog: catalog, options: options)
            return
        }

        try verifyHelmExists(at: options.helmPath)
        try applyVersionMetadata(catalog: catalog, options: options)

        if options.includeAppInfo {
            try applySharedAppInformation(catalog: catalog, options: options)
        }
    }

    public static func commandArguments(
        locale: LocaleMetadata,
        localizationID: String,
        includeAppInfo: Bool,
        keywordsOnly: Bool
    ) -> [String] {
        var arguments = [
            "localization",
            localizationID,
            "update",
            "--keywords",
            locale.keywords,
        ]
        if !keywordsOnly {
            arguments += [
                "--promotional-text",
                locale.promotionalText,
                "--description",
                locale.description,
                "--whats-new",
                locale.whatsNew,
            ]
        }
        if includeAppInfo {
            arguments += [
                "--name",
                locale.name,
                "--subtitle",
                locale.subtitle,
            ]
        }
        arguments.append("--agent")
        return arguments
    }

    private static func applyVersionMetadata(
        catalog: MetadataCatalog,
        options: MetadataApplyOptions
    ) throws {
        for platformName in catalog.platformDrafts.keys.sorted() {
            guard let draft = catalog.platformDrafts[platformName] else { continue }

            for locale in catalog.orderedLocales {
                guard let localizationID = draft.localizationIDs[locale.code] else {
                    throw MetadataToolError.missingLocalizationIDs([locale.code])
                }
                print("Applying \(platformName) \(locale.code)...")
                try runHelmUpdate(
                    helmPath: options.helmPath,
                    arguments: commandArguments(
                        locale: locale,
                        localizationID: localizationID,
                        includeAppInfo: false,
                        keywordsOnly: options.keywordsOnly
                    )
                )
            }
        }
    }

    private static func applySharedAppInformation(
        catalog: MetadataCatalog,
        options: MetadataApplyOptions
    ) throws {
        guard let draft = catalog.platformDrafts.values.first else { return }

        print("Attempting shared App Information name/subtitle updates...")
        for locale in catalog.orderedLocales {
            guard let localizationID = draft.localizationIDs[locale.code] else {
                throw MetadataToolError.missingLocalizationIDs([locale.code])
            }
            try runHelmUpdate(
                helmPath: options.helmPath,
                arguments: commandArguments(
                    locale: locale,
                    localizationID: localizationID,
                    includeAppInfo: true,
                    keywordsOnly: false
                )
            )
        }
    }

    private static func printApplyPlan(
        catalog: MetadataCatalog,
        options: MetadataApplyOptions
    ) {
        let fields = options.keywordsOnly
            ? ["keywords"]
            : ["keywords", "promotional text", "description", "What's New"]
        let appInfoFields = options.includeAppInfo ? ["name", "subtitle"] : []

        print("Catalog valid: RetroRapid \(catalog.version) (\(catalog.submissionStatus))")
        print("Fields: \((fields + appInfoFields).joined(separator: ", "))")
        for platformName in catalog.platformDrafts.keys.sorted() {
            guard let draft = catalog.platformDrafts[platformName] else { continue }
            print(
                "\(platformName) \(catalog.version): "
                    + "\(draft.localizationIDs.count) locales (\(draft.versionID))"
            )
        }
        print("Dry run complete; App Store Connect was not changed.")
    }

    private static func verifyHelmExists(at path: String) throws {
        guard FileManager.default.fileExists(atPath: path) else {
            throw MetadataToolError.helmNotFound(path)
        }
    }

    private static func runHelmUpdate(
        helmPath: String,
        arguments: [String]
    ) throws {
        do {
            let output = try ProcessRunner.run(
                ProcessCommand(executable: helmPath, arguments: arguments),
                captureOutput: true
            )
            print(output.isEmpty ? "  ok" : "  \(output)")
        } catch {
            throw MetadataToolError.helmFailed(error.localizedDescription)
        }
    }
}
