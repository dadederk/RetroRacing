//
//  PauseStateTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 2026-03-27.
//

import XCTest
@testable import RetroRacingShared

final class PauseStateTests: XCTestCase {
    func testGivenSceneAndUserArePausedWhenCheckingExplicitUserPauseThenItIsTrue() {
        // Given
        let pauseState = PauseState(scenePaused: true, isUserPaused: true)

        // When
        let isExplicitUserPauseActive = pauseState.isExplicitUserPauseActive

        // Then
        XCTAssertTrue(isExplicitUserPauseActive)
    }

    func testGivenSceneIsImplicitlyPausedWhenCheckingExplicitUserPauseThenItIsFalse() {
        // Given
        let pauseState = PauseState(scenePaused: true, isUserPaused: false)

        // When
        let isExplicitUserPauseActive = pauseState.isExplicitUserPauseActive

        // Then
        XCTAssertFalse(isExplicitUserPauseActive)
    }

    func testGivenSceneIsRunningWhenCheckingExplicitUserPauseThenItIsFalse() {
        // Given
        let pauseState = PauseState(scenePaused: false, isUserPaused: true)

        // When
        let isExplicitUserPauseActive = pauseState.isExplicitUserPauseActive

        // Then
        XCTAssertFalse(isExplicitUserPauseActive)
    }
}
