//
//  GameControllerActionRouterTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 2026-03-02.
//

import XCTest
@testable import RetroRacingShared

final class GameControllerActionRouterTests: XCTestCase {

    // MARK: - Directional routing (state-independent)

    func testGivenMoveLeftActionWhenMenuHiddenThenMoveLeftIsReturned() {
        // Given / When
        let result = GameControllerActionRouter.route(action: .moveLeft, isMenuOverlayVisible: false)

        // Then
        XCTAssertEqual(result, .moveLeft)
    }

    func testGivenMoveLeftActionWhenMenuVisibleThenMoveLeftIsReturned() {
        // Given / When
        let result = GameControllerActionRouter.route(action: .moveLeft, isMenuOverlayVisible: true)

        // Then
        XCTAssertEqual(result, .moveLeft, "Directional actions are not affected by menu state")
    }

    func testGivenMoveRightActionWhenMenuHiddenThenMoveRightIsReturned() {
        // Given / When
        let result = GameControllerActionRouter.route(action: .moveRight, isMenuOverlayVisible: false)

        // Then
        XCTAssertEqual(result, .moveRight)
    }

    func testGivenMoveRightActionWhenMenuVisibleThenMoveRightIsReturned() {
        // Given / When
        let result = GameControllerActionRouter.route(action: .moveRight, isMenuOverlayVisible: true)

        // Then
        XCTAssertEqual(result, .moveRight, "Directional actions are not affected by menu state")
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
