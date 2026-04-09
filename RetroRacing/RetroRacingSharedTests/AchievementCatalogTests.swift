//
//  AchievementCatalogTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 01/03/2026.
//

import XCTest
@testable import RetroRacingShared

final class AchievementCatalogTests: XCTestCase {
    func testGivenCatalogWhenEnumeratingDefinitionsThenContainsExpectedCount() {
        // Given
        let expectedCount = 22

        // When
        let definitions = AchievementCatalog.definitions

        // Then
        XCTAssertEqual(definitions.count, expectedCount)
    }

    func testGivenRunOvertakesWhenEvaluatingForRunThenOnlyIncludesThresholdsCrossedThisRun() {
        // Given
        let snapshot = AchievementProgressSnapshot(
            bestRunOvertakes: 0,
            cumulativeOvertakes: 0,
            lifetimeUsedControls: [],
            achievedAchievementIDs: []
        )

        // When — run scored 250, so only 100 and 200 thresholds are crossed
        let achieved = AchievementCatalog.achievedAchievementsForRun(runOvertakes: 250, snapshot: snapshot)

        // Then
        XCTAssertTrue(achieved.contains(.runOvertakes100))
        XCTAssertTrue(achieved.contains(.runOvertakes200))
        XCTAssertFalse(achieved.contains(.runOvertakes300))
        XCTAssertFalse(achieved.contains(.runOvertakes400))
    }

    func testGivenHighStoredBestButLowerRunScoreWhenEvaluatingForRunThenOnlyIncludesCurrentRunThresholds() {
        // Given — historical best is 299 but the current run only scored 125
        let snapshot = AchievementProgressSnapshot(
            bestRunOvertakes: 299,
            cumulativeOvertakes: 5_000,
            lifetimeUsedControls: [],
            achievedAchievementIDs: []
        )

        // When
        let achieved = AchievementCatalog.achievedAchievementsForRun(runOvertakes: 125, snapshot: snapshot)

        // Then — 125 crosses 100 but NOT 200; stored best of 299 must not leak into the award
        XCTAssertTrue(achieved.contains(.runOvertakes100))
        XCTAssertFalse(achieved.contains(.runOvertakes200))
    }

    func testGivenRunOvertakesWhenEvaluatingForRunThenCumulativeAchievementsUseSnapshotNotRunScore() {
        // Given — snapshot already has 1_100 cumulative; run adds 50 → total 1_150
        let snapshot = AchievementProgressSnapshot(
            bestRunOvertakes: 0,
            cumulativeOvertakes: 1_100,
            lifetimeUsedControls: [],
            achievedAchievementIDs: []
        )

        // When — a modest 50-overtake run, but cumulative in the snapshot crosses 1k
        let achieved = AchievementCatalog.achievedAchievementsForRun(runOvertakes: 50, snapshot: snapshot)

        // Then — cumulative is evaluated against the snapshot (already ≥ 1k), not the run score
        XCTAssertTrue(achieved.contains(.totalOvertakes1k))
        XCTAssertFalse(achieved.contains(.runOvertakes100))
    }

    func testGivenBestRunThresholdWhenEvaluatingAchievementsThenIncludesReachedRunAchievements() {
        // Given
        let snapshot = AchievementProgressSnapshot(
            bestRunOvertakes: 600,
            cumulativeOvertakes: 0,
            lifetimeUsedControls: [],
            achievedAchievementIDs: []
        )

        // When
        let achieved = AchievementCatalog.achievedAchievements(for: snapshot)

        // Then
        XCTAssertTrue(achieved.contains(.runOvertakes100))
        XCTAssertTrue(achieved.contains(.runOvertakes200))
        XCTAssertTrue(achieved.contains(.runOvertakes300))
        XCTAssertTrue(achieved.contains(.runOvertakes400))
        XCTAssertTrue(achieved.contains(.runOvertakes500))
        XCTAssertTrue(achieved.contains(.runOvertakes600))
        XCTAssertFalse(achieved.contains(.runOvertakes700))
    }

    func testGivenCumulativeThresholdWhenEvaluatingAchievementsThenIncludesReachedTotalAchievements() {
        // Given
        let snapshot = AchievementProgressSnapshot(
            bestRunOvertakes: 0,
            cumulativeOvertakes: 50_000,
            lifetimeUsedControls: [],
            achievedAchievementIDs: []
        )

        // When
        let achieved = AchievementCatalog.achievedAchievements(for: snapshot)

        // Then
        XCTAssertTrue(achieved.contains(.totalOvertakes1k))
        XCTAssertTrue(achieved.contains(.totalOvertakes5k))
        XCTAssertTrue(achieved.contains(.totalOvertakes10k))
        XCTAssertTrue(achieved.contains(.totalOvertakes20k))
        XCTAssertTrue(achieved.contains(.totalOvertakes50k))
        XCTAssertFalse(achieved.contains(.totalOvertakes100k))
    }

    func testGivenLifetimeControlUsageWhenEvaluatingAchievementsThenIncludesControlAchievement() {
        // Given
        let snapshot = AchievementProgressSnapshot(
            bestRunOvertakes: 0,
            cumulativeOvertakes: 0,
            lifetimeUsedControls: [.digitalCrown, .gameController],
            achievedAchievementIDs: []
        )

        // When
        let achieved = AchievementCatalog.achievedAchievements(for: snapshot)

        // Then
        XCTAssertTrue(achieved.contains(.controlDigitalCrown))
        XCTAssertTrue(achieved.contains(.controlGameController))
        XCTAssertFalse(achieved.contains(.controlTap))
    }

    func testGivenGAADCompletionFlagWhenEvaluatingAchievementsThenIncludesGAADAchievement() {
        // Given
        let snapshot = AchievementProgressSnapshot(
            bestRunOvertakes: 0,
            cumulativeOvertakes: 0,
            lifetimeUsedControls: [],
            gaadAssistiveRunCompleted: true,
            achievedAchievementIDs: []
        )

        // When
        let achieved = AchievementCatalog.achievedAchievements(for: snapshot)

        // Then
        XCTAssertTrue(achieved.contains(.eventGAADAssistive))
    }

    func testGivenYearWhenComputingThirdThursdayOfMayThenReturnsExpectedDate() {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current

        // When
        let gaad2024 = AchievementCatalog.thirdThursdayOfMay(in: 2024, calendar: calendar)
        let gaad2025 = AchievementCatalog.thirdThursdayOfMay(in: 2025, calendar: calendar)
        let gaad2026 = AchievementCatalog.thirdThursdayOfMay(in: 2026, calendar: calendar)

        // Then
        XCTAssertEqual(calendar.component(.day, from: gaad2024 ?? .distantPast), 16)
        XCTAssertEqual(calendar.component(.day, from: gaad2025 ?? .distantPast), 15)
        XCTAssertEqual(calendar.component(.day, from: gaad2026 ?? .distantPast), 21)
    }

    func testGivenYearWhenComputingGAADWeekThenIntervalMatchesExpectedMondayToSunday() {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current

        // When
        let interval = AchievementCatalog.gaadWeekDateInterval(forYear: 2026, calendar: calendar)
        let start = interval?.start
        let endExclusive = interval?.end

        // Then
        let startComponents = calendar.dateComponents([.year, .month, .day], from: start ?? .distantPast)
        let endComponents = calendar.dateComponents([.year, .month, .day], from: endExclusive ?? .distantPast)
        XCTAssertEqual(startComponents.year, 2026)
        XCTAssertEqual(startComponents.month, 5)
        XCTAssertEqual(startComponents.day, 18)
        XCTAssertEqual(endComponents.year, 2026)
        XCTAssertEqual(endComponents.month, 5)
        XCTAssertEqual(endComponents.day, 25)
    }

    func testGivenBoundaryDatesWhenCheckingGAADWeekThenOnlyWindowDatesMatch() {
        // Given
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current
        let beforeWindow = calendar.date(from: DateComponents(year: 2026, month: 5, day: 17, hour: 23, minute: 59, second: 59))
        let windowStart = calendar.date(from: DateComponents(year: 2026, month: 5, day: 18, hour: 0, minute: 0, second: 0))
        let windowEnd = calendar.date(from: DateComponents(year: 2026, month: 5, day: 24, hour: 23, minute: 59, second: 59))
        let afterWindow = calendar.date(from: DateComponents(year: 2026, month: 5, day: 25, hour: 0, minute: 0, second: 0))

        // When
        let isBeforeInside = AchievementCatalog.isDateInGAADWeek(beforeWindow ?? .distantPast, calendar: calendar)
        let isStartInside = AchievementCatalog.isDateInGAADWeek(windowStart ?? .distantPast, calendar: calendar)
        let isEndInside = AchievementCatalog.isDateInGAADWeek(windowEnd ?? .distantPast, calendar: calendar)
        let isAfterInside = AchievementCatalog.isDateInGAADWeek(afterWindow ?? .distantPast, calendar: calendar)

        // Then
        XCTAssertFalse(isBeforeInside)
        XCTAssertTrue(isStartInside)
        XCTAssertTrue(isEndInside)
        XCTAssertFalse(isAfterInside)
    }
}
