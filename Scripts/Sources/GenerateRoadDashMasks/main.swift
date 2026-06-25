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
        containing: ["RetroRacing/RetroRacing.xcodeproj", "Requirements/road_markers.md"]
    )
    let mode: RoadMaskMode = arguments.contains("--check") ? .check : .write
    try RoadMaskWorkflow.run(repositoryRoot: repositoryRoot, mode: mode)
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
