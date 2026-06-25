//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import RetroRapidMetadataCore

private let defaultHelmPath =
    "/Applications/Helm.app/Contents/Helpers/helm-asc"

do {
    let arguments = Array(CommandLine.arguments.dropFirst())
    let options = try makeApplyOptions(from: arguments)
    let paths = try MetadataRepositoryPaths.locate()
    let catalog = try MetadataCatalogLoader.loadValidatedCatalog(
        from: paths.defaultCatalog
    )

    try HelmMetadataWorkflow.applyCatalog(catalog, options: options)
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}

private func makeApplyOptions(
    from arguments: [String]
) throws -> MetadataApplyOptions {
    let keywordsOnly = arguments.contains("--keywords-only")
    let includeAppInfo = arguments.contains("--include-app-info")

    guard !(keywordsOnly && includeAppInfo) else {
        throw MetadataToolError.invalidArguments(
            "--keywords-only cannot be combined with --include-app-info."
        )
    }

    return MetadataApplyOptions(
        helmPath: value(after: "--helm", in: arguments) ?? defaultHelmPath,
        keywordsOnly: keywordsOnly,
        includeAppInfo: includeAppInfo,
        dryRun: arguments.contains("--dry-run")
    )
}

private func value(
    after flag: String,
    in arguments: [String]
) -> String? {
    guard
        let flagIndex = arguments.firstIndex(of: flag),
        arguments.indices.contains(flagIndex + 1)
    else {
        return nil
    }
    return arguments[flagIndex + 1]
}
