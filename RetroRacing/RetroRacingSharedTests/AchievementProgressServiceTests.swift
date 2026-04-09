//
//  AchievementProgressServiceTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 01/03/2026.
//

import XCTest
@testable import RetroRacingShared

final class AchievementProgressServiceTests: XCTestCase {
    private var highestScoreStore: MockHighestScoreStore!
    private var store: MockAchievementProgressStore!
    private var reporter: MockAchievementProgressReporter!
    private var service: LocalAchievementProgressService!

    override func setUp() {
        super.setUp()
        highestScoreStore = MockHighestScoreStore()
        store = MockAchievementProgressStore()
        reporter = MockAchievementProgressReporter()
        service = LocalAchievementProgressService(
            store: store,
            highestScoreStore: highestScoreStore,
            reporter: reporter
        )
    }

    override func tearDown() {
        service = nil
        reporter = nil
        store = nil
        highestScoreStore = nil
        super.tearDown()
    }

    func testGivenMissingBackfillWhenPerformingBackfillThenUsesMaxAndSumFromPerDifficultyBestScores() {
        // Given
        _ = highestScoreStore.updateIfHigher(100, for: .cruise)
        _ = highestScoreStore.updateIfHigher(250, for: .fast)
        _ = highestScoreStore.updateIfHigher(400, for: .rapid)

        // When
        service.performInitialBackfillIfNeeded()
        let snapshot = service.currentProgress()

        // Then
        XCTAssertEqual(snapshot.bestRunOvertakes, 400)
        XCTAssertEqual(snapshot.cumulativeOvertakes, 750)
        XCTAssertEqual(snapshot.backfillVersion, 1)
        XCTAssertTrue(snapshot.achievedAchievementIDs.contains(.runOvertakes100))
        XCTAssertTrue(snapshot.achievedAchievementIDs.contains(.runOvertakes200))
    }

    func testGivenBackfillAlreadyAppliedWhenPerformingBackfillThenSnapshotRemainsUnchanged() {
        // Given
        store.snapshot = AchievementProgressSnapshot(
            bestRunOvertakes: 900,
            cumulativeOvertakes: 10_000,
            lifetimeUsedControls: [],
            achievedAchievementIDs: [.runOvertakes800],
            backfillVersion: 1
        )
        _ = highestScoreStore.updateIfHigher(100, for: .rapid)

        // When
        service.performInitialBackfillIfNeeded()
        let snapshot = service.currentProgress()

        // Then
        XCTAssertEqual(snapshot.bestRunOvertakes, 900)
        XCTAssertEqual(snapshot.cumulativeOvertakes, 10_000)
        XCTAssertEqual(reporter.reported.count, 0)
    }

    func testGivenCompletedRunWhenRecordingThenUpdatesSnapshotAndReportsNewAchievements() {
        // Given
        let run = CompletedRunAchievementData(
            overtakes: 1_200,
            usedControls: [.tap, .voiceOver, .gameController]
        )

        // When
        let update = service.recordCompletedRun(run)

        // Then
        XCTAssertEqual(update.snapshot.bestRunOvertakes, 1_200)
        XCTAssertEqual(update.snapshot.cumulativeOvertakes, 1_200)
        XCTAssertTrue(update.snapshot.lifetimeUsedControls.contains(.tap))
        XCTAssertTrue(update.snapshot.lifetimeUsedControls.contains(.voiceOver))
        XCTAssertTrue(update.newlyAchievedAchievementIDs.contains(.runOvertakes800))
        XCTAssertTrue(update.newlyAchievedAchievementIDs.contains(.totalOvertakes1k))
        XCTAssertTrue(update.newlyAchievedAchievementIDs.contains(.controlTap))
        XCTAssertTrue(update.newlyAchievedAchievementIDs.contains(.controlVoiceOver))
        XCTAssertTrue(update.newlyAchievedAchievementIDs.contains(.controlGameController))
    }

    func testGivenExistingProgressHigherThanBackfillWhenPerformingBackfillThenDoesNotRegress() {
        // Given
        store.snapshot = AchievementProgressSnapshot(
            bestRunOvertakes: 3_000,
            cumulativeOvertakes: 15_000,
            lifetimeUsedControls: [.swipe],
            achievedAchievementIDs: [.totalOvertakes10k],
            backfillVersion: nil
        )
        _ = highestScoreStore.updateIfHigher(100, for: .cruise)
        _ = highestScoreStore.updateIfHigher(200, for: .fast)
        _ = highestScoreStore.updateIfHigher(300, for: .rapid)

        // When
        service.performInitialBackfillIfNeeded()
        let snapshot = service.currentProgress()

        // Then
        XCTAssertEqual(snapshot.bestRunOvertakes, 3_000)
        XCTAssertEqual(snapshot.cumulativeOvertakes, 15_000)
        XCTAssertTrue(snapshot.lifetimeUsedControls.contains(.swipe))
    }

    func testGivenGAADWeekAssistiveRunWhenRecordingThenGAADAchievementIsAchieved() {
        // Given
        let run = CompletedRunAchievementData(
            overtakes: 120,
            usedControls: [.tap],
            completedAt: makeUTCDate(year: 2026, month: 5, day: 21, hour: 12, minute: 0, second: 0),
            activeAssistiveTechnologies: [.switchControl]
        )

        // When
        let update = service.recordCompletedRun(run)

        // Then
        XCTAssertEqual(update.snapshot.gaadAssistiveRunCompleted, true)
        XCTAssertTrue(update.snapshot.achievedAchievementIDs.contains(.eventGAADAssistive))
        XCTAssertTrue(update.newlyAchievedAchievementIDs.contains(.eventGAADAssistive))
    }

    func testGivenGAADWeekWithoutAssistiveRunWhenRecordingThenGAADAchievementIsNotAchieved() {
        // Given
        let run = CompletedRunAchievementData(
            overtakes: 120,
            usedControls: [.tap],
            completedAt: makeUTCDate(year: 2026, month: 5, day: 22, hour: 9, minute: 0, second: 0),
            activeAssistiveTechnologies: []
        )

        // When
        let update = service.recordCompletedRun(run)

        // Then
        XCTAssertNotEqual(update.snapshot.gaadAssistiveRunCompleted, true)
        XCTAssertFalse(update.snapshot.achievedAchievementIDs.contains(.eventGAADAssistive))
        XCTAssertFalse(update.newlyAchievedAchievementIDs.contains(.eventGAADAssistive))
    }

    func testGivenAssistiveRunOutsideGAADWeekWhenRecordingThenGAADAchievementIsNotAchieved() {
        // Given
        let run = CompletedRunAchievementData(
            overtakes: 120,
            usedControls: [.tap],
            completedAt: makeUTCDate(year: 2026, month: 6, day: 1, hour: 10, minute: 0, second: 0),
            activeAssistiveTechnologies: [.voiceOver]
        )

        // When
        let update = service.recordCompletedRun(run)

        // Then
        XCTAssertNotEqual(update.snapshot.gaadAssistiveRunCompleted, true)
        XCTAssertFalse(update.snapshot.achievedAchievementIDs.contains(.eventGAADAssistive))
        XCTAssertFalse(update.newlyAchievedAchievementIDs.contains(.eventGAADAssistive))
    }

    func testGivenGAADAchievementAlreadyCompletedWhenRecordingNonEligibleRunThenCompletionFlagStaysTrue() {
        // Given
        store.snapshot = AchievementProgressSnapshot(
            bestRunOvertakes: 0,
            cumulativeOvertakes: 0,
            lifetimeUsedControls: [],
            gaadAssistiveRunCompleted: true,
            achievedAchievementIDs: [.eventGAADAssistive],
            backfillVersion: 1
        )
        let run = CompletedRunAchievementData(
            overtakes: 50,
            usedControls: [.tap],
            completedAt: makeUTCDate(year: 2026, month: 7, day: 1, hour: 10, minute: 0, second: 0),
            activeAssistiveTechnologies: []
        )

        // When
        let update = service.recordCompletedRun(run)

        // Then
        XCTAssertEqual(update.snapshot.gaadAssistiveRunCompleted, true)
        XCTAssertTrue(update.snapshot.achievedAchievementIDs.contains(.eventGAADAssistive))
    }

    func testGivenAchievedAchievementsWhenReplayingThenReporterReceivesAllAchievedIDs() {
        // Given
        store.snapshot = AchievementProgressSnapshot(
            bestRunOvertakes: 0,
            cumulativeOvertakes: 0,
            lifetimeUsedControls: [],
            gaadAssistiveRunCompleted: true,
            achievedAchievementIDs: [.controlTap, .eventGAADAssistive],
            backfillVersion: 1
        )

        // When
        service.replayAchievedAchievements()

        // Then
        XCTAssertEqual(reporter.reported.count, 1)
        XCTAssertEqual(reporter.reported.first, Set([.controlTap, .eventGAADAssistive]))
    }

    func testGivenNoAchievedAchievementsWhenReplayingThenReporterIsNotCalled() {
        // Given
        store.snapshot = .empty

        // When
        service.replayAchievedAchievements()

        // Then
        XCTAssertTrue(reporter.reported.isEmpty)
    }

    private func makeUTCDate(
        year: Int,
        month: Int,
        day: Int,
        hour: Int,
        minute: Int,
        second: Int
    ) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? TimeZone.current
        return calendar.date(
            from: DateComponents(
                year: year,
                month: month,
                day: day,
                hour: hour,
                minute: minute,
                second: second
            )
        ) ?? .distantPast
    }
}

private final class MockHighestScoreStore: HighestScoreStore {
    private(set) var highestScores: [GameDifficulty: Int] = [:]

    func currentBest(for difficulty: GameDifficulty) -> Int {
        highestScores[difficulty, default: 0]
    }

    @discardableResult
    func updateIfHigher(_ score: Int, for difficulty: GameDifficulty) -> Bool {
        let existing = highestScores[difficulty, default: 0]
        guard score > existing else { return false }
        highestScores[difficulty] = score
        return true
    }

    func syncFromRemote(bestScore: Int, for difficulty: GameDifficulty) {
        let existing = highestScores[difficulty, default: 0]
        if bestScore > existing {
            highestScores[difficulty] = bestScore
        }
    }
}

private final class MockAchievementProgressStore: AchievementProgressStore {
    var snapshot = AchievementProgressSnapshot.empty

    func load() -> AchievementProgressSnapshot {
        snapshot
    }

    func save(_ snapshot: AchievementProgressSnapshot) {
        self.snapshot = snapshot
    }
}

private final class MockAchievementProgressReporter: AchievementProgressReporter {
    private(set) var reported: [Set<AchievementIdentifier>] = []

    func reportAchievedAchievements(_ achievementIDs: Set<AchievementIdentifier>) {
        guard achievementIDs.isEmpty == false else { return }
        reported.append(achievementIDs)
    }
}
