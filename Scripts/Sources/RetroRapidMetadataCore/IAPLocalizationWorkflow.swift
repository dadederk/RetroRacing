//
//  IAPLocalizationWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import ScriptSupport

public struct IAPLocalizationApplyOptions: Sendable {
    public let helmPath: String
    public let iapID: String
    public let bundleRelativePath: String
    public let locales: [String]
    public let dryRun: Bool

    public init(
        helmPath: String,
        iapID: String,
        bundleRelativePath: String,
        locales: [String],
        dryRun: Bool
    ) {
        self.helmPath = helmPath
        self.iapID = iapID
        self.bundleRelativePath = bundleRelativePath
        self.locales = locales
        self.dryRun = dryRun
    }
}

public enum IAPLocalizationWorkflow {
    private struct DownloadResponse: Decodable, Sendable {
        let rootPath: String
        let status: String?
    }

    public static func apply(
        repositoryRoot: URL,
        options: IAPLocalizationApplyOptions
    ) throws {
        try HelmCLI.verifyExists(at: options.helmPath)

        let sourceRoot = repositoryRoot
            .appending(path: options.bundleRelativePath)
        let sourceBundle = sourceRoot.path(percentEncoded: false)
        guard FileManager.default.fileExists(atPath: sourceBundle) else {
            throw MetadataToolError.invalidArguments(
                "Missing IAP bundle at \(options.bundleRelativePath)."
            )
        }

        print("Uploading Unlimited Plays IAP localizations from \(sourceBundle)...")
        let directOutput = try upload(
            helmPath: options.helmPath,
            iapID: options.iapID,
            uploadPath: sourceBundle,
            locales: options.locales,
            dryRun: options.dryRun
        )

        if HelmCLI.isNoopAgentResponse(directOutput) == false {
            print(directOutput.isEmpty ? "ok" : directOutput)
            if options.dryRun == false {
                try printVerification(helmPath: options.helmPath, iapID: options.iapID)
            }
            return
        }

        print(
            """
            Helm CLI cannot read the repo bundle (folder grant in Helm does not apply to \
            helm-asc file reads). Staging under Helm's IAP download artifact directory...
            """
        )

        let artifactRoot = try downloadArtifactRoot(
            helmPath: options.helmPath,
            iapID: options.iapID
        )
        try mergeSourceBundle(
            from: sourceRoot,
            into: URL(fileURLWithPath: artifactRoot, isDirectory: true),
            locales: options.locales
        )

        let stagedOutput = try upload(
            helmPath: options.helmPath,
            iapID: options.iapID,
            uploadPath: artifactRoot,
            locales: options.locales,
            dryRun: options.dryRun
        )

        if HelmCLI.isNoopAgentResponse(stagedOutput) {
            throw MetadataToolError.helmFailed(
                """
                Helm returned noop after staging under \(artifactRoot). \
                If --dry-run was used, retry without --dry-run; IAP upload dry-run may not \
                plan new locales. Otherwise confirm Helm is running and copy \
                \(options.locales.joined(separator: ", ")) folders into that path manually.
                """
            )
        }

        print(stagedOutput.isEmpty ? "ok" : stagedOutput)

        if options.dryRun == false {
            try printVerification(helmPath: options.helmPath, iapID: options.iapID)
        }
    }

    private static func downloadArtifactRoot(
        helmPath: String,
        iapID: String
    ) throws -> String {
        let output = try HelmCLI.run(
            helmPath: helmPath,
            arguments: [
                "inAppPurchase", iapID, "localizations", "download",
                "--agent",
            ]
        )
        guard let data = output.data(using: .utf8) else {
            throw MetadataToolError.helmFailed("Helm download output was not UTF-8.")
        }
        let response = try JSONDecoder().decode(DownloadResponse.self, from: data)
        guard response.status == "ok" else {
            throw MetadataToolError.helmFailed("Helm IAP localization download failed.")
        }
        guard FileManager.default.fileExists(atPath: response.rootPath) else {
            throw MetadataToolError.helmFailed(
                "Helm download rootPath is missing: \(response.rootPath)"
            )
        }
        print("Helm artifact root: \(response.rootPath)")
        return response.rootPath
    }

    private static func upload(
        helmPath: String,
        iapID: String,
        uploadPath: String,
        locales: [String],
        dryRun: Bool
    ) throws -> String {
        var arguments = [
            "inAppPurchase", iapID, "localizations", "upload",
            "--path", uploadPath,
        ]
        for locale in locales {
            arguments += ["--locale", locale]
        }
        if dryRun {
            arguments.append("--dry-run")
        }
        arguments.append("--agent")
        return try HelmCLI.run(helmPath: helmPath, arguments: arguments)
    }

    private static func mergeSourceBundle(
        from sourceRoot: URL,
        into artifactRoot: URL,
        locales: [String]
    ) throws {
        for locale in locales {
            let sourceCSV = sourceRoot
                .appending(path: locale)
                .appending(path: "metadata.csv")
            guard FileManager.default.fileExists(atPath: sourceCSV.path) else {
                throw MetadataToolError.invalidArguments(
                    "Missing \(locale)/metadata.csv in repo bundle."
                )
            }

            let destinationDirectory = artifactRoot.appending(path: locale)
            try FileManager.default.createDirectory(
                at: destinationDirectory,
                withIntermediateDirectories: true
            )
            let destinationCSV = destinationDirectory.appending(path: "metadata.csv")
            if FileManager.default.fileExists(atPath: destinationCSV.path) {
                try FileManager.default.removeItem(at: destinationCSV)
            }
            try FileManager.default.copyItem(at: sourceCSV, to: destinationCSV)
        }
    }

    private static func printVerification(helmPath: String, iapID: String) throws {
        print("Verify:")
        let output = try HelmCLI.run(
            helmPath: helmPath,
            arguments: ["inAppPurchase", iapID, "localizations", "--agent"]
        )
        print(output)
    }
}
