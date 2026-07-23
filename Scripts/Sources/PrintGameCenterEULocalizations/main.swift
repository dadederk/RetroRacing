//
//  main.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import RetroRapidMetadataCore
import ScriptSupport

do {
    let paths = try MetadataRepositoryPaths.locate()
    let catalogURL = paths.repositoryRoot
        .appending(path: "AppStore/game-center/achievements-eu-localizations.json")
    let catalog = try GameCenterAchievementLocalizationCatalog.load(from: catalogURL)
    print(catalog.renderedChecklist())
} catch {
    fputs("\(error.localizedDescription)\n", stderr)
    exit(1)
}
