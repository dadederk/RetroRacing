//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 24/07/2026.
//

import Foundation
import RetroRapidMetadataCore
import ScriptSupport

do {
    let arguments = CLIArguments()
    CLIHelp.exitIfRequested(arguments, usage: CLIUsageTexts.swapAppStoreScreenshots)
    let options = try HelmScreenshotSwapOptionsParser.parse(arguments)
    _ = try HelmScreenshotSwapWorkflow.run(options: options)
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
