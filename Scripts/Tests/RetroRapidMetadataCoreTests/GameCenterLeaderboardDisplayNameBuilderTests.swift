//
//  GameCenterLeaderboardDisplayNameBuilderTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import Testing

@testable import RetroRapidMetadataCore

@Test
func givenIPhoneCruiseWhenBuildingGermanDisplayNameThenHighScoreIsTranslatedAndLevelStaysCruise() {
    let name = GameCenterLeaderboardDisplayNameBuilder.displayName(
        platform: "iPhone",
        difficulty: "cruise",
        locale: "de-DE",
        englishReferenceName: "iPhone High Score - Cruise"
    )

    #expect(name == "iPhone Bestpunktzahl - Cruise")
}

@Test
func givenIPhoneFastWhenBuildingFrenchDisplayNameThenFastLevelMatchesInAppTranslation() {
    let name = GameCenterLeaderboardDisplayNameBuilder.displayName(
        platform: "iPhone",
        difficulty: "fast",
        locale: "fr-FR",
        englishReferenceName: "iPhone High Score - Fast"
    )

    #expect(name == "iPhone Meilleur score - Rapide")
}

@Test
func givenSpanishLocaleWhenBuildingDisplayNameThenUsesMejorPuntuacionAndRapido() {
    let name = GameCenterLeaderboardDisplayNameBuilder.displayName(
        platform: "iPhone",
        difficulty: "fast",
        locale: "es-ES",
        englishReferenceName: "iPhone High Score - Fast"
    )
    #expect(name == "iPhone Top score - Rápido")
}

@Test
func givenCatalanLocaleWhenBuildingDisplayNameThenUsesMillorPuntuacioAndRapid() {
    let name = GameCenterLeaderboardDisplayNameBuilder.displayName(
        platform: "iPhone",
        difficulty: "fast",
        locale: "ca",
        englishReferenceName: "iPhone High Score - Fast"
    )
    #expect(name == "iPhone Top score - Ràpid")
}

@Test
func givenMacBoardWhenEnglishReferenceMissingThenDefaultPlatformPrefixIsUsed() {
    let name = GameCenterLeaderboardDisplayNameBuilder.displayName(
        platform: "macOS",
        difficulty: "rapid",
        locale: "nl-NL",
        englishReferenceName: nil
    )

    #expect(name == "Mac Highscore - Rapid")
}

@Test
func givenItalianIPhoneBoardWhenBuildingDisplayNameThenShortHighScorePhraseIsUsed() {
    let name = GameCenterLeaderboardDisplayNameBuilder.displayName(
        platform: "iPhone",
        difficulty: "cruise",
        locale: "it",
        englishReferenceName: "iPhone High Score - Cruise"
    )

    #expect(name == "iPhone Top score - Cruise")
}

@Test
func givenAppleWatchFrenchBoardWhenBuildingDisplayNameThenPlatformAndPhraseAreCompact() {
    let name = GameCenterLeaderboardDisplayNameBuilder.displayName(
        platform: "watchOS",
        difficulty: "fast",
        locale: "fr-FR",
        englishReferenceName: "Apple Watch High Score - Fast"
    )

    #expect(name == "Apple Watch Top score - Rapide")
    #expect(name.count <= GameCenterLeaderboardDisplayNameBuilder.maxDisplayNameLength)
}

@Test
func givenShippingLeaderboardCatalogWhenBuildingAllEUDisplayNamesThenEachFitsAscLimit() throws {
    let repositoryRoot = try MetadataRepositoryPaths.locate().repositoryRoot
    let catalogURL = repositoryRoot
        .appending(path: "AppStore/game-center/leaderboards-eu-localizations.json")
    let catalog = try GameCenterLeaderboardLocalizationCatalog.load(from: catalogURL)

    let englishReferenceNames: [String: String] = [
        "iPhone": "iPhone High Score - Cruise",
        "iPad": "iPad High Score - Cruise",
        "macOS": "Mac High Score - Cruise",
        "watchOS": "Apple Watch High Score - Cruise",
    ]

    for leaderboard in catalog.leaderboards {
        let englishReferenceName = englishReferenceNames[leaderboard.platform]
        for locale in catalog.locales {
            let name = GameCenterLeaderboardDisplayNameBuilder.displayName(
                platform: leaderboard.platform,
                difficulty: leaderboard.difficulty,
                locale: locale,
                englishReferenceName: englishReferenceName
            )
            #expect(
                name.count <= GameCenterLeaderboardDisplayNameBuilder.maxDisplayNameLength,
                "Expected '\(name)' for \(leaderboard.referenceName) [\(locale)] to fit ASC limit"
            )
            #expect(name.count >= 2)
        }
    }
}
