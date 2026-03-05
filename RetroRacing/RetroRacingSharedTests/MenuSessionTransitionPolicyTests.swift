//
//  MenuSessionTransitionPolicyTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 05/03/2026.
//

import XCTest
@testable import RetroRacingShared

final class MenuSessionTransitionPolicyTests: XCTestCase {
    func testGivenActiveSessionWhenRequestingPlayThenNewSessionStartsAndMenuIsDismissed() {
        // Given
        let previousSessionID = UUID()
        let newSessionID = UUID()
        let currentState = MenuSessionState(
            shouldStartGame: true,
            isMenuPresented: true,
            sessionID: previousSessionID
        )

        // When
        let nextState = MenuSessionTransitionPolicy.stateAfterPlayRequest(
            from: currentState,
            newSessionID: newSessionID
        )

        // Then
        XCTAssertTrue(nextState.shouldStartGame)
        XCTAssertFalse(nextState.isMenuPresented)
        XCTAssertEqual(nextState.sessionID, newSessionID)
        XCTAssertNotEqual(nextState.sessionID, previousSessionID)
    }

    func testGivenPreGameStateWhenRequestingPlayThenSessionStartsFromBeginning() {
        // Given
        let previousSessionID = UUID()
        let newSessionID = UUID()
        let currentState = MenuSessionState(
            shouldStartGame: false,
            isMenuPresented: true,
            sessionID: previousSessionID
        )

        // When
        let nextState = MenuSessionTransitionPolicy.stateAfterPlayRequest(
            from: currentState,
            newSessionID: newSessionID
        )

        // Then
        XCTAssertTrue(nextState.shouldStartGame)
        XCTAssertFalse(nextState.isMenuPresented)
        XCTAssertEqual(nextState.sessionID, newSessionID)
        XCTAssertNotEqual(nextState.sessionID, previousSessionID)
    }

    func testGivenAnySessionWhenRequestingFinishThenPreGameStateAndMenuAreRestored() {
        // Given
        let previousSessionID = UUID()
        let newSessionID = UUID()
        let currentState = MenuSessionState(
            shouldStartGame: true,
            isMenuPresented: false,
            sessionID: previousSessionID
        )

        // When
        let nextState = MenuSessionTransitionPolicy.stateAfterFinishRequest(
            from: currentState,
            newSessionID: newSessionID
        )

        // Then
        XCTAssertFalse(nextState.shouldStartGame)
        XCTAssertTrue(nextState.isMenuPresented)
        XCTAssertEqual(nextState.sessionID, newSessionID)
        XCTAssertNotEqual(nextState.sessionID, previousSessionID)
    }
}
