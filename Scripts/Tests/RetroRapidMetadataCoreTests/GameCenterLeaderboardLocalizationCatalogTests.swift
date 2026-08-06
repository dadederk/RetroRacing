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
func givenLeaderboardCatalogWhenLoadedThenFifteenConfiguredBoardsExist() throws {
    let repositoryRoot = try MetadataRepositoryPaths.locate().repositoryRoot
    let catalogURL = repositoryRoot
        .appending(path: "AppStore/game-center/leaderboards-eu-localizations.json")
    let catalog = try GameCenterLeaderboardLocalizationCatalog.load(from: catalogURL)

    #expect(catalog.leaderboards.count == 15)
    #expect(catalog.locales == [
        "de-DE", "nl-NL", "it", "fr-FR", "fr-CA", "es-ES", "es-MX", "ca",
        "ja", "ko", "pt-BR", "pt-PT", "zh-Hant", "zh-Hans",
        "tr", "pl",
    ])
    #expect(catalog.leaderboards.first?.vendorLeaderboardId == "bestios001cruise")
    let appleTVBoards = catalog.leaderboards.filter { $0.platform == "tvOS" }
    #expect(appleTVBoards.count == 3)
    #expect(appleTVBoards.allSatisfy { $0.templateVendorLeaderboardId != nil })
    for leaderboard in appleTVBoards {
        for locale in catalog.locales {
            #expect(catalog.localizationCopy(for: locale, leaderboard: leaderboard) != nil)
        }
    }
}

@Test
func givenProvisioningModeWhenSelectingLeaderboardsThenOnlyTemplateBackedBoardsAreIncluded() throws {
    let repositoryRoot = try MetadataRepositoryPaths.locate().repositoryRoot
    let catalog = try GameCenterLeaderboardLocalizationCatalog.load(
        from: repositoryRoot.appending(
            path: "AppStore/game-center/leaderboards-eu-localizations.json"
        )
    )

    let selected = AppStoreConnectGameCenterClient.selectedLeaderboards(
        in: catalog,
        ensureMissingLeaderboards: true
    )

    #expect(selected.count == 3)
    #expect(Set(selected.map(\.platform)) == ["tvOS"])
    #expect(selected.allSatisfy { $0.templateVendorLeaderboardId != nil })
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
