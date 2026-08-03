//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation
import RetroRacingAutomationCore
import ScriptSupport

do {
    let arguments = CLIArguments()
    if arguments.contains("--help") || arguments.contains("-h") {
        print(CLIUsageTexts.optimizeRuntimeAssets())
        exit(0)
    }
    let repositoryRoot = try RepositoryLocator.locate(
        containing: [
            "RetroRacing/RetroRacing.xcodeproj",
            "AssetSources/RuntimeFootprint2026-08-02/optimize-runtime-assets.mjs",
        ]
    )
    let options = try RuntimeAssetOptimizationOptions.parse(arguments)
    try RuntimeAssetOptimizationWorkflow.run(
        repositoryRoot: repositoryRoot,
        options: options,
        transformer: ImageMagickRuntimeAssetTransformer(
            processRunner: SystemRuntimeAssetProcessRunner()
        )
    )
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
