//
//  Command.swift
//  RetroRacing
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation
import RetroRacingAutomationCore
import ScriptSupport

@main
struct GenerateSpatialAssetsCommand {
    @MainActor
    static func main() async {
        do {
            let repositoryRoot = try RepositoryLocator.locate(
                containing: [SpatialAssetWorkflow.configurationPath]
            )
            let options = try SpatialAssetOptions.parse(CLIArguments())
            try await SpatialAssetWorkflow.run(
                repositoryRoot: repositoryRoot,
                options: options
            )
        } catch {
            fputs("\(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }
}
