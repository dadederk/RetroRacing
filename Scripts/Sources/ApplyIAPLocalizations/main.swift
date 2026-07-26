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
private let defaultLocales = [
    "de-DE", "nl-NL", "it", "fr-FR",
    "es-ES", "es-MX", "ca",
    "ja", "ko", "pt-BR", "zh-Hant",
]

do {
    let arguments = CLIArguments()
    CLIHelp.exitIfRequested(arguments, usage: CLIUsageTexts.applyIAPLocalizations)
    try arguments.rejectUnknownFlags(
        allowing: ["--dry-run", "--check", "--asc-api"],
        valueFlags: ["--helm"]
    )

    let paths = try MetadataRepositoryPaths.locate()
    let options = IAPLocalizationApplyOptions(
        helmPath: try HelmCLI.resolvePath(from: arguments),
        iapID: defaultIAPID,
        bundleRelativePath: defaultBundleRelativePath,
        locales: defaultLocales,
        dryRun: arguments.contains("--dry-run"),
        preferAppStoreConnectAPI: arguments.contains("--asc-api")
    )

    if arguments.contains("--check") {
        try IAPLocalizationWorkflow.check(
            repositoryRoot: paths.repositoryRoot,
            options: options
        )
    } else {
        try IAPLocalizationWorkflow.apply(
            repositoryRoot: paths.repositoryRoot,
            options: options
        )
    }
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
