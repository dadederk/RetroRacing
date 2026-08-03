//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 02/08/2026.
//

import Foundation
import RetroRacingAutomationCore
import ScriptSupport

do {
    let arguments = CLIArguments()
    if arguments.contains("--help") || arguments.contains("-h") {
        print(CLIUsageTexts.assetAudit())
        exit(0)
    }
    try arguments.rejectUnknownFlags(allowing: ["--check", "--full"])
    let repositoryRoot = try RepositoryLocator.locate(
        containing: ["RetroRacing/RetroRacing.xcodeproj", "Scripts/Resources/runtime_asset_manifest.json"]
    )
    try AssetAuditWorkflow.run(
        repositoryRoot: repositoryRoot,
        options: AssetAuditOptions(
            check: arguments.contains("--check"),
            full: arguments.contains("--full")
        )
    )
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
