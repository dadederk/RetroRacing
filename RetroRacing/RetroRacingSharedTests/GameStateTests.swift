//
//  GameStateTests.swift
//  RetroRacingSharedTests
//
//  Created by Cursor on 2026-02-13.
//

import XCTest
@testable import RetroRacingShared

final class GameStateTests: XCTestCase {
    func testGivenScoreBelow97WhenCheckingLevelChangeImminentThenReturnsFalse() {
        // Given
        let scores = [0, 50, 96]

        // When / Then
        for score in scores {
            XCTAssertFalse(GameState.isLevelChangeImminent(score: score), "score \(score) should not be imminent")
        }
    }

    func testGivenScore97To99WhenCheckingLevelChangeImminentThenReturnsTrue() {
        // Given
        let scores = [97, 98, 99]

        // When / Then
        for score in scores {
            XCTAssertTrue(GameState.isLevelChangeImminent(score: score), "score \(score) should be imminent")
        }
    }

    func testGivenScore100WhenCheckingLevelChangeImminentThenReturnsFalse() {
        // Given
        let score = 100

        // When
        let result = GameState.isLevelChangeImminent(score: score)

        // Then
        XCTAssertFalse(result)
    }

    func testGivenScore197To199WhenCheckingLevelChangeImminentThenReturnsTrue() {
        // Given
        let scores = [197, 198, 199]

        // When / Then
        for score in scores {
            XCTAssertTrue(GameState.isLevelChangeImminent(score: score), "score \(score) should be imminent")
        }
    }

    func testGivenScore200WhenCheckingLevelChangeImminentThenReturnsFalse() {
        // Given
        let score = 200

        // When
        let result = GameState.isLevelChangeImminent(score: score)

        // Then
        XCTAssertFalse(result)
    }

    func testGivenCustomWindowPointsWhenCheckingLevelChangeImminentThenUsesWindow() {
        // Given: window of 10 points (90–99)
        let windowPoints = 10

        // When / Then
        XCTAssertFalse(GameState.isLevelChangeImminent(score: 89, windowPoints: windowPoints))
        XCTAssertTrue(GameState.isLevelChangeImminent(score: 90, windowPoints: windowPoints))
        XCTAssertTrue(GameState.isLevelChangeImminent(score: 99, windowPoints: windowPoints))
        XCTAssertFalse(GameState.isLevelChangeImminent(score: 100, windowPoints: windowPoints))
    }

    func testGivenDefaultSpeedAlertWindowWhenReadingWindowThenUsesThreePoints() {
        // Given

        // When
        let windowPoints = GameState.defaultSpeedAlertWindowPoints

        // Then
        XCTAssertEqual(windowPoints, 3)
    }

    func testGivenVisibleRowsCrossLevelOnFourthUpdateWhenCalculatingOffsetThenReturnsThree() {
        // Given
        let score = 96
        let upcomingRowPoints = [1, 1, 1, 1]

        // When
        let result = GameState.updatesUntilNextLevelChange(score: score, upcomingRowPoints: upcomingRowPoints)

        // Then
        XCTAssertEqual(result, 3)
    }

    func testGivenVisibleRowsCrossLevelOnThirdUpdateWhenCalculatingOffsetThenReturnsTwo() {
        // Given
        let score = 97
        let upcomingRowPoints = [1, 1, 1, 0]

        // When
        let result = GameState.updatesUntilNextLevelChange(score: score, upcomingRowPoints: upcomingRowPoints)

        // Then
        XCTAssertEqual(result, 2)
    }

    func testGivenVisibleRowsDoNotCrossLevelWhenCalculatingOffsetThenReturnsNil() {
        // Given
        let score = 97
        let upcomingRowPoints = [0, 1, 1, 0]

        // When
        let result = GameState.updatesUntilNextLevelChange(score: score, upcomingRowPoints: upcomingRowPoints)

        // Then
        XCTAssertNil(result)
    }
}
