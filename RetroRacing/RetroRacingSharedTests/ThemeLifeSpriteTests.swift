//
//  ThemeLifeSpriteTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 2026-08-02.
//

import SwiftUI
import XCTest
@testable import RetroRacingShared

final class ThemeLifeSpriteTests: XCTestCase {
    func testGivenBuiltInThemesWhenResolvingFriendLifeSpriteThenThemeArtIsReturned() {
        // Given
        let cases: [(theme: any GameTheme, expectedAssetName: String)] = [
            (LCDTheme(), "friendLife-LCD"),
            (PocketTheme(), "friendLife-GameBoy"),
            (EightBitTheme(), "friendLife-8Bit"),
            (SixteenBitTheme(), "friendLife-16Bit"),
        ]

        // When / Then
        for testCase in cases {
            XCTAssertEqual(testCase.theme.resolvedFriendLifeSprite(), testCase.expectedAssetName)
        }
    }

    func testGivenMissingFriendArtWhenResolvingThenPlayerArtAndLCDFallbackAreUsed() {
        // Given
        let playerOnlyTheme = FallbackTheme(lifeAssetName: "custom-player-life")
        let noLifeArtTheme = FallbackTheme(lifeAssetName: nil)

        // When
        let playerFallback = playerOnlyTheme.resolvedFriendLifeSprite()
        let lcdFallback = noLifeArtTheme.resolvedFriendLifeSprite()

        // Then
        XCTAssertEqual(playerFallback, "custom-player-life")
        XCTAssertEqual(lcdFallback, "life-LCD")
    }
}

private struct FallbackTheme: GameTheme {
    let lifeAssetName: String?

    var id: ThemeID { ThemeID(rawValue: "fallback") }
    var name: String { "Fallback" }
    var isPremium: Bool { false }

    func backgroundColor(for state: GameState) -> Color { .clear }
    func gridLineColor() -> Color { .gray }
    func playerCarColor() -> Color { .blue }
    func rivalCarColor() -> Color { .red }
    func crashColor() -> Color { .orange }
    func textColor() -> Color { .primary }
    func cellBorderWidth() -> CGFloat { 1 }
    func cornerRadius() -> CGFloat { 0 }
    func lifeSprite() -> String? { lifeAssetName }
}
