//
//  InGameHelpPresentationPolicyTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 19/02/2026.
//

import XCTest
@testable import RetroRacingShared

final class InGameHelpPresentationPolicyTests: XCTestCase {
    func testGivenVoiceOverEnabledAndTutorialNotSeenWhenEvaluatingThenAutoPresentationIsAllowed() {
        // Given

        // When
        let shouldPresent = InGameHelpPresentationPolicy.shouldAutoPresent(
            voiceOverRunning: true,
            hasSeenTutorial: false,
            shouldStartGame: true,
            hasScene: true,
            isScenePaused: false
        )

        // Then
        XCTAssertTrue(shouldPresent)
    }

    func testGivenTutorialAlreadySeenWhenEvaluatingThenAutoPresentationIsNotAllowed() {
        // Given

        // When
        let shouldPresent = InGameHelpPresentationPolicy.shouldAutoPresent(
            voiceOverRunning: true,
            hasSeenTutorial: true,
            shouldStartGame: true,
            hasScene: true,
            isScenePaused: false
        )

        // Then
        XCTAssertFalse(shouldPresent)
    }

    func testGivenSceneIsPausedWhenEvaluatingThenAutoPresentationIsNotAllowed() {
        // Given

        // When
        let shouldPresent = InGameHelpPresentationPolicy.shouldAutoPresent(
            voiceOverRunning: true,
            hasSeenTutorial: false,
            shouldStartGame: true,
            hasScene: true,
            isScenePaused: true
        )

        // Then
        XCTAssertFalse(shouldPresent)
    }
}
