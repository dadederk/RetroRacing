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
    #expect(catalog.locales == [
        "de-DE", "nl-NL", "it", "fr-FR", "fr-CA", "es-ES", "es-MX", "ca",
        "ja", "ko", "pt-BR", "pt-PT", "zh-Hant", "zh-Hans",
        "tr", "pl",
    ])
    #expect(catalog.renderedChecklist().contains("Serie 100"))
    #expect(catalog.renderedChecklist().contains("Racha 100"))
    #expect(catalog.renderedChecklist().contains("Ratxa 100"))
    #expect(catalog.renderedChecklist().contains("Seri 100"))
    #expect(catalog.renderedChecklist().contains("Seria 100"))
    #expect(catalog.renderedChecklist().contains("apply-game-center-eu-localizations"))
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
