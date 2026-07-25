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
    let options = try HelmScreenshotSwapOptionsParser.parse(CLIArguments())
    _ = try HelmScreenshotSwapWorkflow.run(options: options)
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
