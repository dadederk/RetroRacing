//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import RetroRacingAutomationCore
import ScriptSupport

do {
    let repositoryRoot = try RepositoryLocator.locate(
        containing: [
            "AppStore/RetroRapid.screenshotstudio",
            "RetroRacing/RetroRacing.xcodeproj",
        ]
    )
    let plans = try AppStoreScreenshotCaptureOptions.parsePlans(
        CLIArguments(),
        repositoryRoot: repositoryRoot
    )
    for (index, options) in plans.enumerated() {
        if plans.count > 1 {
            print(
                "=== [\(index + 1)/\(plans.count)] \(options.platform) " +
                "(force=\(options.forceRecapture), locales=\(options.locales.count), " +
                "slides=\(options.slideIndexes.count)) ==="
            )
        }
        try AppStoreScreenshotCaptureWorkflow.run(
            repositoryRoot: repositoryRoot,
            options: options
        )
    }
    if plans.count > 1 {
        print("All-platform screenshot capture finished (\(plans.count) platform(s)).")
    }
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
