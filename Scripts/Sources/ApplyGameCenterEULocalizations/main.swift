//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import RetroRapidMetadataCore
import ScriptSupport

private let defaultAppID = "6758641625"
private let achievementsCatalogRelativePath = "AppStore/game-center/achievements-eu-localizations.json"
private let leaderboardsCatalogRelativePath = "AppStore/game-center/leaderboards-eu-localizations.json"

do {
    let arguments = CLIArguments()
    CLIHelp.exitIfRequested(arguments, usage: CLIUsageTexts.applyGameCenterEULocalizations)
    try arguments.rejectUnknownFlags(
        allowing: ["--dry-run", "--check", "--achievements-only", "--leaderboards-only"],
        valueFlags: []
    )

    if arguments.contains("--achievements-only") && arguments.contains("--leaderboards-only") {
        throw MetadataToolError.invalidArguments(
            "Use only one of --achievements-only or --leaderboards-only."
        )
    }

    let includeAchievements = arguments.contains("--leaderboards-only") == false
    let includeLeaderboards = arguments.contains("--achievements-only") == false

    let paths = try MetadataRepositoryPaths.locate()
    let options = GameCenterEULocalizationApplyOptions(
        appID: defaultAppID,
        achievementsCatalogRelativePath: achievementsCatalogRelativePath,
        leaderboardsCatalogRelativePath: leaderboardsCatalogRelativePath,
        includeAchievements: includeAchievements,
        includeLeaderboards: includeLeaderboards,
        dryRun: arguments.contains("--dry-run")
    )

    if arguments.contains("--check") {
        try GameCenterEULocalizationWorkflow.check(
            repositoryRoot: paths.repositoryRoot,
            options: options
        )
    } else {
        try GameCenterEULocalizationWorkflow.apply(
            repositoryRoot: paths.repositoryRoot,
            options: options
        )
    }
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
