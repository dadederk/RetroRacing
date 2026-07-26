//
//  GameCenterLeaderboardLocalizationCatalogTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import Testing

@testable import RetroRapidMetadataCore

@Test
func givenLeaderboardCatalogWhenLoadedThenTwelveShippingBoardsExist() throws {
    let repositoryRoot = try MetadataRepositoryPaths.locate().repositoryRoot
    let catalogURL = repositoryRoot
        .appending(path: "AppStore/game-center/leaderboards-eu-localizations.json")
    let catalog = try GameCenterLeaderboardLocalizationCatalog.load(from: catalogURL)

    #expect(catalog.leaderboards.count == 12)
    #expect(catalog.locales == [
        "de-DE", "nl-NL", "it", "fr-FR", "fr-CA", "es-ES", "ca",
        "ja", "ko", "pt-BR", "pt-PT", "zh-Hant", "zh-Hans",
    ])
    #expect(catalog.leaderboards.first?.vendorLeaderboardId == "bestios001cruise")
}

@Test
func givenGameCenterLocalizationListWhenParsingThenLocalesMap() {
    let json: [String: Any] = [
        "data": [
            [
                "type": "gameCenterAchievementLocalizations",
                "id": "loc-de",
                "attributes": ["locale": "de-DE"],
            ],
        ],
    ]

    #expect(AppStoreConnectGameCenterClient.localizationIDsByLocale(from: json) == ["de-DE": "loc-de"])
}
