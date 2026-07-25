//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 10/07/2026.
//

import Foundation
import RetroRacingAutomationCore
import ScriptSupport

do {
    let arguments = CLIArguments()
    if arguments.contains("-h") || arguments.contains("--help") {
        print(TestFlightUploadOptionsParser.usageText())
        exit(0)
    }

    let repositoryRoot = try RepositoryLocator.locate(
        containing: ["RetroRacing/RetroRacing.xcodeproj", "Scripts/Package.swift"]
    )
    let options = try TestFlightUploadOptionsParser.parse(arguments)
    try TestFlightUploadWorkflow.run(repositoryRoot: repositoryRoot, options: options)
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
