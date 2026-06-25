//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import RetroRapidMetadataCore
import ScriptSupport

private let defaultHelmPath =
    "/Applications/Helm.app/Contents/Helpers/helm-asc"

do {
    let options = try makeApplyOptions(from: CLIArguments())
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
    from arguments: CLIArguments
) throws -> MetadataApplyOptions {
    try arguments.rejectUnknownFlags(
        allowing: ["--keywords-only", "--include-app-info", "--dry-run"],
        valueFlags: ["--helm"]
    )
    let keywordsOnly = arguments.contains("--keywords-only")
    let includeAppInfo = arguments.contains("--include-app-info")

    guard !(keywordsOnly && includeAppInfo) else {
        throw MetadataToolError.invalidArguments(
            "--keywords-only cannot be combined with --include-app-info."
        )
    }

    return MetadataApplyOptions(
        helmPath: try arguments.value(after: "--helm") ?? defaultHelmPath,
        keywordsOnly: keywordsOnly,
        includeAppInfo: includeAppInfo,
        dryRun: arguments.contains("--dry-run")
    )
}
