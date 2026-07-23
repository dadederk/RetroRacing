//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import RetroRapidMetadataCore
import ScriptSupport

private let defaultIAPID = "6759012658"
private let defaultBundleRelativePath = "AppStore/iap-localizations/6759012658"
private let defaultLocales = ["de-DE", "nl-NL", "it", "fr-FR"]

do {
    let arguments = CLIArguments()
    try arguments.rejectUnknownFlags(
        allowing: ["--dry-run"],
        valueFlags: ["--helm"]
    )

    let paths = try MetadataRepositoryPaths.locate()
    try IAPLocalizationWorkflow.apply(
        repositoryRoot: paths.repositoryRoot,
        options: IAPLocalizationApplyOptions(
            helmPath: try HelmCLI.resolvePath(from: arguments),
            iapID: defaultIAPID,
            bundleRelativePath: defaultBundleRelativePath,
            locales: defaultLocales,
            dryRun: arguments.contains("--dry-run")
        )
    )
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
