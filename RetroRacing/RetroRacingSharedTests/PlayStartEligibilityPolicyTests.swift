//
//  PlayStartEligibilityPolicyTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 22/07/2026.
//

import XCTest
@testable import RetroRacingShared

final class PlayStartEligibilityPolicyTests: XCTestCase {
    func testGivenPremiumAccessWhenEvaluatingDecisionThenStartsGame() {
        // Given
        let hasUnlimitedAccessForGating = true

        // When
        let decision = PlayStartEligibilityPolicy.decision(
            hasUnlimitedAccessForGating: hasUnlimitedAccessForGating,
            isSpecialEventActive: false,
            playLimitServiceExists: true,
            canStartNewGame: false
        )

        // Then
        XCTAssertEqual(decision, .startGame)
    }

    func testGivenSpecialEventWhenEvaluatingDecisionThenStartsGame() {
        // Given
        let isSpecialEventActive = true

        // When
        let decision = PlayStartEligibilityPolicy.decision(
            hasUnlimitedAccessForGating: false,
            isSpecialEventActive: isSpecialEventActive,
            playLimitServiceExists: true,
            canStartNewGame: false
        )

        // Then
        XCTAssertEqual(decision, .startGame)
    }

    func testGivenPlayLimitReachedWhenEvaluatingDecisionThenShowsLimitPaywall() {
        // Given
        let canStartNewGame = false

        // When
        let decision = PlayStartEligibilityPolicy.decision(
            hasUnlimitedAccessForGating: false,
            isSpecialEventActive: false,
            playLimitServiceExists: true,
            canStartNewGame: canStartNewGame
        )

        // Then
        XCTAssertEqual(decision, .showLimitPaywall)
    }

    func testGivenNoPlayLimitServiceWhenEvaluatingDecisionThenStartsGame() {
        // Given
        let playLimitServiceExists = false

        // When
        let decision = PlayStartEligibilityPolicy.decision(
            hasUnlimitedAccessForGating: false,
            isSpecialEventActive: false,
            playLimitServiceExists: playLimitServiceExists,
            canStartNewGame: false
        )

        // Then
        XCTAssertEqual(decision, .startGame)
    }
}
