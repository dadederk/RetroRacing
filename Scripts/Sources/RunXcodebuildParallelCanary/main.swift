//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 01/08/2026.
//

import Foundation
import RetroRacingAutomationCore
import ScriptSupport

do {
    let configuration = try ParallelTestCanaryConfiguration.parse(
        Array(CommandLine.arguments.dropFirst())
    )
    let repositoryRoot = try RepositoryLocator.locate(
        containing: ["RetroRacing/RetroRacing.xcodeproj", "Requirements/testing.md"]
    )
    try ParallelTestCanaryWorkflow.run(
        repositoryRoot: repositoryRoot,
        configuration: configuration
    )
} catch ParallelTestCanaryError.helpRequested {
    printUsage()
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}

private func printUsage() {
    print(
        """
        Usage: swift run --package-path Scripts run-xcodebuild-parallel-canary [options]

          --scheme <name>                 Default: RetroRacingUniversal
          --destination <value>           Default: platform=iOS Simulator,name=iPhone 17 Pro
          --workers <n[,n]>               Default: 2,4
          --dry-run
          --help
        """
    )
}
