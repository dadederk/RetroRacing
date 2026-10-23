//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 18/10/2026.
//

import Foundation
import RetroRacingAutomationCore
import ScriptSupport

do {
    let arguments = CLIArguments()
    try arguments.rejectUnknownFlags(allowing: ["--check", "--dry-run"])
    guard arguments.contains("--check") == false || arguments.contains("--dry-run") == false else {
        throw ScriptSupportError.unexpectedArgument("--check and --dry-run are mutually exclusive")
    }
    let repositoryRoot = try RepositoryLocator.locate(
        containing: ["AppStore/README.md", "Scripts/Package.swift"]
    )
    let mode: AppStoreCreativeMode
    if arguments.contains("--check") {
        mode = .check
    } else if arguments.contains("--dry-run") {
        mode = .dryRun
    } else {
        mode = .write
    }
    try AppStoreCreativeWorkflow.run(repositoryRoot: repositoryRoot, mode: mode)
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
