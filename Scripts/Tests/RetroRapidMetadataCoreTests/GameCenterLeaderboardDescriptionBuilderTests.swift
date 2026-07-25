//
//  GameCenterLeaderboardDescriptionBuilderTests.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Testing

@testable import RetroRapidMetadataCore

@Test
func givenEnglishLeaderboardDescriptionWhenBuildingGermanThenOvertakeRunPhraseIsTranslated() {
    let description = GameCenterLeaderboardDescriptionBuilder.description(
        locale: "de-DE",
        englishReferenceDescription: "Overtake as many cars as you can in one run."
    )

    #expect(description == "Überhole so viele Autos wie möglich in einem Lauf.")
}

@Test
func givenMissingEnglishReferenceWhenBuildingFrenchDescriptionThenDefaultCopyIsUsed() {
    let description = GameCenterLeaderboardDescriptionBuilder.description(
        locale: "fr-FR",
        englishReferenceDescription: nil
    )

    #expect(description == "Dépasse autant de voitures que possible en une seule partie.")
}
