//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation
import RetroRacingAutomationCore
import ScriptSupport

do {
    let arguments = CLIArguments()
    try arguments.rejectUnknownFlags(allowing: ["--check"])
    let repositoryRoot = try RepositoryLocator.locate(
        containing: [
            "AppStore/RetroRapid.screenshotstudio",
            "AppStore/docs/06-screenshots.md",
        ]
    )
    let mode: ScreenshotStudioMode = arguments.contains("--check")
        ? .check
        : .write
    try ScreenshotStudioWorkflow.run(
        repositoryRoot: repositoryRoot,
        mode: mode
    )
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
