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
    public let preferAppStoreConnectAPI: Bool

    public init(
        helmPath: String,
        iapID: String,
        bundleRelativePath: String,
        locales: [String],
        dryRun: Bool,
        preferAppStoreConnectAPI: Bool = false
    ) {
        self.helmPath = helmPath
        self.iapID = iapID
        self.bundleRelativePath = bundleRelativePath
        self.locales = locales
        self.dryRun = dryRun
        self.preferAppStoreConnectAPI = preferAppStoreConnectAPI
    }
}

public enum IAPLocalizationWorkflow {
    private struct DownloadResponse: Decodable, Sendable {
        let rootPath: String
        let status: String?
    }

    public static func check(
        repositoryRoot: URL,
        options: IAPLocalizationApplyOptions
    ) throws {
        let sourceRoot = repositoryRoot.appending(path: options.bundleRelativePath)
        guard FileManager.default.fileExists(atPath: sourceRoot.path) else {
            throw MetadataToolError.invalidArguments(
                "Missing IAP bundle at \(options.bundleRelativePath)."
            )
        }

        let localizations = try loadLocalizations(from: sourceRoot, locales: options.locales)
        for localization in localizations {
            print("Validated \(localization.locale): \(localization.name)")
        }
        print("IAP localization bundle is valid for \(localizations.count) locales.")
    }

    public static func apply(
        repositoryRoot: URL,
        options: IAPLocalizationApplyOptions
    ) throws {
        let sourceRoot = repositoryRoot.appending(path: options.bundleRelativePath)
        let sourceBundle = sourceRoot.path(percentEncoded: false)
        guard FileManager.default.fileExists(atPath: sourceBundle) else {
            throw MetadataToolError.invalidArguments(
                "Missing IAP bundle at \(options.bundleRelativePath)."
            )
        }

        let localizations = try loadLocalizations(from: sourceRoot, locales: options.locales)

        if options.preferAppStoreConnectAPI {
            try applyViaAppStoreConnectAPI(
                iapID: options.iapID,
                localizations: localizations,
                dryRun: options.dryRun
            )
            return
        }

        try applyViaHelm(
            sourceRoot: sourceRoot,
            sourceBundle: sourceBundle,
            localizations: localizations,
            options: options
        )
    }

    private static func applyViaHelm(
        sourceRoot: URL,
        sourceBundle: String,
        localizations: [IAPPurchaseLocalizationCopy],
        options: IAPLocalizationApplyOptions
    ) throws {
        try HelmCLI.verifyExists(at: options.helmPath)

        print("Uploading Unlimited Plays IAP localizations from \(sourceBundle)...")
        let directOutput = try uploadViaHelm(
            helmPath: options.helmPath,
            iapID: options.iapID,
            uploadPath: sourceBundle,
            locales: options.locales,
            dryRun: options.dryRun
        )

        if HelmCLI.isNoopAgentResponse(directOutput) == false {
            print(directOutput.isEmpty ? "ok" : directOutput)
            if options.dryRun == false {
                try printHelmVerification(helmPath: options.helmPath, iapID: options.iapID)
            }
            return
        }

        print(
            """
            Helm CLI cannot read the repo bundle. Trying Helm artifact staging...
            """
        )

        do {
            let artifactRoot = try downloadArtifactRoot(
                helmPath: options.helmPath,
                iapID: options.iapID
            )
            try mergeSourceBundle(
                from: sourceRoot,
                into: URL(fileURLWithPath: artifactRoot, isDirectory: true),
                locales: options.locales
            )

            let stagedOutput = try uploadViaHelm(
                helmPath: options.helmPath,
                iapID: options.iapID,
                uploadPath: artifactRoot,
                locales: options.locales,
                dryRun: options.dryRun
            )

            if HelmCLI.isNoopAgentResponse(stagedOutput) == false {
                print(stagedOutput.isEmpty ? "ok" : stagedOutput)
                if options.dryRun == false {
                    try printHelmVerification(helmPath: options.helmPath, iapID: options.iapID)
                }
                return
            }
        } catch {
            print("Helm artifact staging failed: \(error.localizedDescription)")
        }

        if AppStoreConnectCredentialsLoader.load() != nil {
            print("Falling back to App Store Connect API...")
            try applyViaAppStoreConnectAPI(
                iapID: options.iapID,
                localizations: localizations,
                dryRun: options.dryRun
            )
            return
        }

        let helmArtifactHint = helmArtifactPathHint(iapID: options.iapID)

        throw MetadataToolError.invalidArguments(
            """
            Helm could not upload IAP localizations and Terminal cannot write into Helm's \
            Group Containers folder. Choose one workaround:

            1. Finder copy, then Helm upload:
               open "\(sourceBundle)"
               \(helmArtifactHint)
               Drag de-DE, nl-NL, it, fr-FR, fr-CA, es-ES, es-MX, ca, ja, ko, pt-BR, pt-PT, zh-Hant, zh-Hans, tr, and pl into the Helm folder, then run:
               helm-asc inAppPurchase \(options.iapID) localizations upload --path "<helm folder>" --locale de-DE --locale nl-NL --locale it --locale fr-FR --locale fr-CA --locale es-ES --locale es-MX --locale ca --locale ja --locale ko --locale pt-BR --locale pt-PT --locale zh-Hant --locale zh-Hans --locale tr --locale pl --agent

            2. App Store Connect API (recommended for automation):
               \(AppStoreConnectCredentialsLoader.missingCredentialsMessage())
               ./retrorapid asc iap --asc-api
            """
        )
    }

    private static func applyViaAppStoreConnectAPI(
        iapID: String,
        localizations: [IAPPurchaseLocalizationCopy],
        dryRun: Bool
    ) throws {
        guard let credentials = AppStoreConnectCredentialsLoader.load() else {
            throw MetadataToolError.invalidArguments(
                AppStoreConnectCredentialsLoader.missingCredentialsMessage()
            )
        }

        let messages = try awaitResult {
            try await AppStoreConnectAPIClient.upsertInAppPurchaseLocalizations(
                iapID: iapID,
                localizations: localizations,
                credentials: credentials,
                dryRun: dryRun
            )
        }
        for message in messages {
            print(message)
        }
    }

    private static func loadLocalizations(
        from sourceRoot: URL,
        locales: [String]
    ) throws -> [IAPPurchaseLocalizationCopy] {
        try locales.map { locale in
            let csvURL = sourceRoot
                .appending(path: locale)
                .appending(path: "metadata.csv")
            guard FileManager.default.fileExists(atPath: csvURL.path) else {
                throw MetadataToolError.invalidArguments(
                    "Missing \(locale)/metadata.csv in repo bundle."
                )
            }
            let rows = try CSVDictionaryReader.read(url: csvURL)
            guard let name = rows["name"], name.isEmpty == false else {
                throw MetadataToolError.invalidArguments("Missing name for \(locale).")
            }
            guard let description = rows["description"], description.isEmpty == false else {
                throw MetadataToolError.invalidArguments("Missing description for \(locale).")
            }
            return IAPPurchaseLocalizationCopy(
                locale: locale,
                name: name,
                description: description
            )
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

    private static func uploadViaHelm(
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
            let destinationDirectory = artifactRoot.appending(path: locale)
            do {
                try FileManager.default.createDirectory(
                    at: destinationDirectory,
                    withIntermediateDirectories: true
                )
                let destinationCSV = destinationDirectory.appending(path: "metadata.csv")
                if FileManager.default.fileExists(atPath: destinationCSV.path) {
                    try FileManager.default.removeItem(at: destinationCSV)
                }
                try FileManager.default.copyItem(at: sourceCSV, to: destinationCSV)
            } catch {
                throw MetadataToolError.invalidArguments(
                    "Could not copy \(locale) into Helm artifact folder (\(artifactRoot.path)): \(error.localizedDescription)"
                )
            }
        }
    }

    private static func helmArtifactPathHint(iapID: String) -> String {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let artifactPath =
            "\(home)/Library/Group Containers/group.com.modumhq.Helm/CLI Artifacts/iap-localizations/\(iapID)"
        return "open \"\(artifactPath)\""
    }

    private static func printHelmVerification(helmPath: String, iapID: String) throws {
        print("Verify:")
        let output = try HelmCLI.run(
            helmPath: helmPath,
            arguments: ["inAppPurchase", iapID, "localizations", "--agent"]
        )
        print(output)
    }

    private static func awaitResult<T: Sendable>(
        _ operation: @Sendable @escaping () async throws -> T
    ) throws -> T {
        let semaphore = DispatchSemaphore(value: 0)
        let box = ResultBox<T>()
        Task {
            do {
                box.result = .success(try await operation())
            } catch {
                box.result = .failure(error)
            }
            semaphore.signal()
        }
        semaphore.wait()
        return try box.result.get()
    }
}

private final class ResultBox<T: Sendable>: @unchecked Sendable {
    var result: Result<T, Error> = .failure(
        MetadataToolError.appStoreConnectFailed("App Store Connect API task did not finish.")
    )
}

enum CSVDictionaryReader {
    static func read(url: URL) throws -> [String: String] {
        let contents = try String(contentsOf: url, encoding: .utf8)
        var values: [String: String] = [:]
        for line in contents.split(whereSeparator: \.isNewline) {
            let parts = line.split(separator: ",", maxSplits: 1).map(String.init)
            guard parts.count == 2 else { continue }
            if parts[0] == "field" { continue }
            values[parts[0]] = parts[1]
        }
        return values
    }
}
