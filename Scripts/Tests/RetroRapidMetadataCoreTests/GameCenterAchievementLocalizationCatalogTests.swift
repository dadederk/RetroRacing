//
//  GameCenterAchievementLocalizationCatalogTests.swift
//  RetroRapidMetadataCoreTests
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import Testing

@testable import RetroRapidMetadataCore

@Test
func givenEUCatalogWhenLoadedThenTwentyTwoAchievementsAcrossFourLocalesExist() throws {
    let repositoryRoot = try MetadataRepositoryPaths.locate().repositoryRoot
    let catalogURL = repositoryRoot
        .appending(path: "AppStore/game-center/achievements-eu-localizations.json")
    let catalog = try GameCenterAchievementLocalizationCatalog.load(from: catalogURL)

    #expect(catalog.achievements.count == 22)
    #expect(catalog.locales == ["de-DE", "nl-NL", "it", "fr-FR"])
    #expect(catalog.renderedChecklist().contains("Serie 100"))
}

@Test
func givenNoopHelmResponseWhenDetectedThenStatusIsRecognized() {
    #expect(
        HelmCLI.isNoopAgentResponse(
            """
            {
              "status" : "noop"
            }
            """
        )
    )
    #expect(
        HelmCLI.isNoopAgentResponse(
            """
            {
              "status" : "ok"
            }
            """
        ) == false
    )
}
