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
    let repositoryRoot = try RepositoryLocator.locate(
        containing: ["RetroRacing/RetroRacing.xcodeproj", "Requirements/testing.md"]
    )
    let options = try TestRunnerOptions.parse(CLIArguments())
    try TestRunnerWorkflow.run(repositoryRoot: repositoryRoot, options: options)
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
