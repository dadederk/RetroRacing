//
//  GameControllerActionRouterTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 2026-03-02.
//

import XCTest
@testable import RetroRacingShared

final class GameControllerActionRouterTests: XCTestCase {

    // MARK: - Directional routing (state-dependent)

    func testGivenMoveLeftActionWhenMenuHiddenThenMoveLeftIsReturned() {
        // Given / When
        let result = GameControllerActionRouter.route(action: .moveLeft, isMenuOverlayVisible: false)

        // Then
        XCTAssertEqual(result, .moveLeft)
    }

    func testGivenMoveLeftActionWhenMenuVisibleThenIgnoredIsReturned() {
        // Given / When
        let result = GameControllerActionRouter.route(action: .moveLeft, isMenuOverlayVisible: true)

        // Then
        XCTAssertEqual(result, .ignored, "Directional actions should be ignored while overlays are visible")
    }

    func testGivenMoveRightActionWhenMenuHiddenThenMoveRightIsReturned() {
        // Given / When
        let result = GameControllerActionRouter.route(action: .moveRight, isMenuOverlayVisible: false)

        // Then
        XCTAssertEqual(result, .moveRight)
    }

    func testGivenMoveRightActionWhenMenuVisibleThenIgnoredIsReturned() {
        // Given / When
        let result = GameControllerActionRouter.route(action: .moveRight, isMenuOverlayVisible: true)

        // Then
        XCTAssertEqual(result, .ignored, "Directional actions should be ignored while overlays are visible")
    }

    // MARK: - Pause/Resume routing (state-dependent)

    func testGivenPauseResumeActionWhenMenuHiddenThenTogglePauseIsReturned() {
        // Given / When
        let result = GameControllerActionRouter.route(action: .pauseResume, isMenuOverlayVisible: false)

        // Then
        XCTAssertEqual(result, .togglePause)
    }

    func testGivenPauseResumeActionWhenMenuVisibleThenRequestPlayIsReturned() {
        // Given / When
        let result = GameControllerActionRouter.route(action: .pauseResume, isMenuOverlayVisible: true)

        // Then
        XCTAssertEqual(result, .requestPlay, "Start/Menu while menu is open should trigger Play, not pause toggle")
    }
}
