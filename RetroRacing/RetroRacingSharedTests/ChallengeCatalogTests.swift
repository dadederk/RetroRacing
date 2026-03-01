//
//  ChallengeCatalogTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 01/03/2026.
//

import XCTest
@testable import RetroRacingShared

final class ChallengeCatalogTests: XCTestCase {
    func testGivenCatalogWhenEnumeratingDefinitionsThenContainsExpectedCount() {
        // Given
        let expectedCount = 18

        // When
        let definitions = ChallengeCatalog.definitions

        // Then
        XCTAssertEqual(definitions.count, expectedCount)
    }

    func testGivenBestRunThresholdWhenEvaluatingAchievementsThenIncludesReachedRunChallenges() {
        // Given
        let snapshot = ChallengeProgressSnapshot(
            bestRunOvertakes: 600,
            cumulativeOvertakes: 0,
            lifetimeUsedControls: [],
            achievedChallengeIDs: []
        )

        // When
        let achieved = ChallengeCatalog.achievedChallenges(for: snapshot)

        // Then
        XCTAssertTrue(achieved.contains(.runOvertakes100))
        XCTAssertTrue(achieved.contains(.runOvertakes200))
        XCTAssertTrue(achieved.contains(.runOvertakes500))
        XCTAssertTrue(achieved.contains(.runOvertakes600))
        XCTAssertFalse(achieved.contains(.runOvertakes700))
    }

    func testGivenCumulativeThresholdWhenEvaluatingAchievementsThenIncludesReachedTotalChallenges() {
        // Given
        let snapshot = ChallengeProgressSnapshot(
            bestRunOvertakes: 0,
            cumulativeOvertakes: 50_000,
            lifetimeUsedControls: [],
            achievedChallengeIDs: []
        )

        // When
        let achieved = ChallengeCatalog.achievedChallenges(for: snapshot)

        // Then
        XCTAssertTrue(achieved.contains(.totalOvertakes1k))
        XCTAssertTrue(achieved.contains(.totalOvertakes5k))
        XCTAssertTrue(achieved.contains(.totalOvertakes10k))
        XCTAssertTrue(achieved.contains(.totalOvertakes20k))
        XCTAssertTrue(achieved.contains(.totalOvertakes50k))
        XCTAssertFalse(achieved.contains(.totalOvertakes100k))
    }

    func testGivenLifetimeControlUsageWhenEvaluatingAchievementsThenIncludesControlChallenge() {
        // Given
        let snapshot = ChallengeProgressSnapshot(
            bestRunOvertakes: 0,
            cumulativeOvertakes: 0,
            lifetimeUsedControls: [.digitalCrown],
            achievedChallengeIDs: []
        )

        // When
        let achieved = ChallengeCatalog.achievedChallenges(for: snapshot)

        // Then
        XCTAssertTrue(achieved.contains(.controlDigitalCrown))
        XCTAssertFalse(achieved.contains(.controlTap))
    }
}
