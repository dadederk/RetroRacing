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
            normalizedHelmArgument(locale.keywords),
        ]
        if !keywordsOnly {
            arguments += [
                "--promotional-text",
                normalizedHelmArgument(locale.promotionalText),
                "--description",
                normalizedHelmArgument(locale.description),
                "--whats-new",
                normalizedHelmArgument(locale.whatsNew),
            ]
        }
        if includeAppInfo {
            arguments += [
                "--name",
                normalizedHelmArgument(locale.name),
                "--subtitle",
                normalizedHelmArgument(locale.subtitle),
            ]
        }
        arguments.append("--agent")
        return arguments
    }

    private static func normalizedHelmArgument(_ value: String) -> String {
        value.precomposedStringWithCanonicalMapping
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
            let output = try runHelmViaPython(
                helmPath: helmPath,
                arguments: arguments
            )
            print(output.isEmpty ? "  ok" : "  \(output)")
        } catch {
            throw MetadataToolError.helmFailed(error.localizedDescription)
        }
    }

    /// Swift `Process` can pass decomposed/non-ASCII argv to `helm-asc`, which ASC rejects.
    private static func runHelmViaPython(
        helmPath: String,
        arguments: [String]
    ) throws -> String {
        let command = [helmPath] + arguments
        let payload = try JSONSerialization.data(withJSONObject: command)
        let script = """
        import json, subprocess, sys
        command = json.loads(sys.stdin.read())
        result = subprocess.run(command, capture_output=True, text=True)
        sys.stdout.write(result.stdout)
        sys.stderr.write(result.stderr)
        sys.exit(result.returncode)
        """
        let process = Process()
        let standardOutput = Pipe()
        let standardError = Pipe()
        let standardInput = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/bin/python3")
        process.arguments = ["-c", script]
        process.standardOutput = standardOutput
        process.standardError = standardError
        process.standardInput = standardInput

        try process.run()
        standardInput.fileHandleForWriting.write(payload)
        try standardInput.fileHandleForWriting.close()
        process.waitUntilExit()

        let output = readText(from: standardOutput)
        let errorOutput = readText(from: standardError)
        guard process.terminationStatus == 0 else {
            throw ScriptSupportError.commandFailed(
                ([helmPath] + arguments).joined(separator: " "),
                process.terminationStatus,
                errorOutput.isEmpty ? output : errorOutput
            )
        }
        return output
    }

    private static func readText(from pipe: Pipe) -> String {
        String(
            data: pipe.fileHandleForReading.readDataToEndOfFile(),
            encoding: .utf8
        )?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}
