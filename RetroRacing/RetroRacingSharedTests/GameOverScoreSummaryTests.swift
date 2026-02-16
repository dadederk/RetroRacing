//
//  GameOverScoreSummaryTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 16/02/2026.
//

import XCTest
@testable import RetroRacingShared

final class GameOverScoreSummaryTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var suiteName: String!
    private var highestScoreStore: UserDefaultsHighestScoreStore!

    override func setUp() {
        super.setUp()
        suiteName = "test.gameover.summary.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        highestScoreStore = UserDefaultsHighestScoreStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        if let suiteName {
            UserDefaults().removePersistentDomain(forName: suiteName)
        }
        highestScoreStore = nil
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testGivenPreviousBestExistsWhenScoreDoesNotBeatBestThenSummaryShowsCurrentBestWithoutPreviousBestLine() {
        // Given
        _ = highestScoreStore.updateIfHigher(120)

        // When
        let summary = highestScoreStore.evaluateGameOverScore(95)

        // Then
        XCTAssertFalse(summary.isNewRecord)
        XCTAssertEqual(summary.score, 95)
        XCTAssertEqual(summary.bestScore, 120)
        XCTAssertNil(summary.previousBestScore)
    }

    func testGivenPreviousBestExistsWhenScoreBeatsBestThenSummaryIncludesPreviousAndNewBest() {
        // Given
        _ = highestScoreStore.updateIfHigher(120)

        // When
        let summary = highestScoreStore.evaluateGameOverScore(135)

        // Then
        XCTAssertTrue(summary.isNewRecord)
        XCTAssertEqual(summary.score, 135)
        XCTAssertEqual(summary.previousBestScore, 120)
        XCTAssertEqual(summary.bestScore, 135)
    }
}
