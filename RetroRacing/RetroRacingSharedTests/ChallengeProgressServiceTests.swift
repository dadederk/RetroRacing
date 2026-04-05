//
//  ChallengeProgressServiceTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 01/03/2026.
//

import XCTest
@testable import RetroRacingShared

final class ChallengeProgressServiceTests: XCTestCase {
    private var highestScoreStore: MockHighestScoreStore!
    private var store: MockChallengeProgressStore!
    private var reporter: MockChallengeProgressReporter!
    private var service: LocalChallengeProgressService!

    override func setUp() {
        super.setUp()
        highestScoreStore = MockHighestScoreStore()
        store = MockChallengeProgressStore()
        reporter = MockChallengeProgressReporter()
        service = LocalChallengeProgressService(
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
        XCTAssertTrue(snapshot.achievedChallengeIDs.contains(.runOvertakes100))
        XCTAssertTrue(snapshot.achievedChallengeIDs.contains(.runOvertakes200))
    }

    func testGivenBackfillAlreadyAppliedWhenPerformingBackfillThenSnapshotRemainsUnchanged() {
        // Given
        store.snapshot = ChallengeProgressSnapshot(
            bestRunOvertakes: 900,
            cumulativeOvertakes: 10_000,
            lifetimeUsedControls: [],
            achievedChallengeIDs: [.runOvertakes800],
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
        let run = CompletedRunChallengeData(
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
        XCTAssertTrue(update.newlyAchievedChallengeIDs.contains(.runOvertakes800))
        XCTAssertTrue(update.newlyAchievedChallengeIDs.contains(.totalOvertakes1k))
        XCTAssertTrue(update.newlyAchievedChallengeIDs.contains(.controlTap))
        XCTAssertTrue(update.newlyAchievedChallengeIDs.contains(.controlVoiceOver))
        XCTAssertTrue(update.newlyAchievedChallengeIDs.contains(.controlGameController))
    }

    func testGivenExistingProgressHigherThanBackfillWhenPerformingBackfillThenDoesNotRegress() {
        // Given
        store.snapshot = ChallengeProgressSnapshot(
            bestRunOvertakes: 3_000,
            cumulativeOvertakes: 15_000,
            lifetimeUsedControls: [.swipe],
            achievedChallengeIDs: [.totalOvertakes10k],
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

    func testGivenGAADWeekAssistiveRunWhenRecordingThenGAADChallengeIsAchieved() {
        // Given
        let run = CompletedRunChallengeData(
            overtakes: 120,
            usedControls: [.tap],
            completedAt: makeUTCDate(year: 2026, month: 5, day: 21, hour: 12, minute: 0, second: 0),
            activeAssistiveTechnologies: [.switchControl]
        )

        // When
        let update = service.recordCompletedRun(run)

        // Then
        XCTAssertEqual(update.snapshot.gaadAssistiveRunCompleted, true)
        XCTAssertTrue(update.snapshot.achievedChallengeIDs.contains(.eventGAADAssistive))
        XCTAssertTrue(update.newlyAchievedChallengeIDs.contains(.eventGAADAssistive))
    }

    func testGivenGAADWeekWithoutAssistiveRunWhenRecordingThenGAADChallengeIsNotAchieved() {
        // Given
        let run = CompletedRunChallengeData(
            overtakes: 120,
            usedControls: [.tap],
            completedAt: makeUTCDate(year: 2026, month: 5, day: 22, hour: 9, minute: 0, second: 0),
            activeAssistiveTechnologies: []
        )

        // When
        let update = service.recordCompletedRun(run)

        // Then
        XCTAssertNotEqual(update.snapshot.gaadAssistiveRunCompleted, true)
        XCTAssertFalse(update.snapshot.achievedChallengeIDs.contains(.eventGAADAssistive))
        XCTAssertFalse(update.newlyAchievedChallengeIDs.contains(.eventGAADAssistive))
    }

    func testGivenAssistiveRunOutsideGAADWeekWhenRecordingThenGAADChallengeIsNotAchieved() {
        // Given
        let run = CompletedRunChallengeData(
            overtakes: 120,
            usedControls: [.tap],
            completedAt: makeUTCDate(year: 2026, month: 6, day: 1, hour: 10, minute: 0, second: 0),
            activeAssistiveTechnologies: [.voiceOver]
        )

        // When
        let update = service.recordCompletedRun(run)

        // Then
        XCTAssertNotEqual(update.snapshot.gaadAssistiveRunCompleted, true)
        XCTAssertFalse(update.snapshot.achievedChallengeIDs.contains(.eventGAADAssistive))
        XCTAssertFalse(update.newlyAchievedChallengeIDs.contains(.eventGAADAssistive))
    }

    func testGivenGAADChallengeAlreadyCompletedWhenRecordingNonEligibleRunThenCompletionFlagStaysTrue() {
        // Given
        store.snapshot = ChallengeProgressSnapshot(
            bestRunOvertakes: 0,
            cumulativeOvertakes: 0,
            lifetimeUsedControls: [],
            gaadAssistiveRunCompleted: true,
            achievedChallengeIDs: [.eventGAADAssistive],
            backfillVersion: 1
        )
        let run = CompletedRunChallengeData(
            overtakes: 50,
            usedControls: [.tap],
            completedAt: makeUTCDate(year: 2026, month: 7, day: 1, hour: 10, minute: 0, second: 0),
            activeAssistiveTechnologies: []
        )

        // When
        let update = service.recordCompletedRun(run)

        // Then
        XCTAssertEqual(update.snapshot.gaadAssistiveRunCompleted, true)
        XCTAssertTrue(update.snapshot.achievedChallengeIDs.contains(.eventGAADAssistive))
    }

    func testGivenAchievedChallengesWhenReplayingThenReporterReceivesAllAchievedIDs() {
        // Given
        store.snapshot = ChallengeProgressSnapshot(
            bestRunOvertakes: 0,
            cumulativeOvertakes: 0,
            lifetimeUsedControls: [],
            gaadAssistiveRunCompleted: true,
            achievedChallengeIDs: [.controlTap, .eventGAADAssistive],
            backfillVersion: 1
        )

        // When
        service.replayAchievedChallenges()

        // Then
        XCTAssertEqual(reporter.reported.count, 1)
        XCTAssertEqual(reporter.reported.first, Set([.controlTap, .eventGAADAssistive]))
    }

    func testGivenNoAchievedChallengesWhenReplayingThenReporterIsNotCalled() {
        // Given
        store.snapshot = .empty

        // When
        service.replayAchievedChallenges()

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

private final class MockChallengeProgressStore: ChallengeProgressStore {
    var snapshot = ChallengeProgressSnapshot.empty

    func load() -> ChallengeProgressSnapshot {
        snapshot
    }

    func save(_ snapshot: ChallengeProgressSnapshot) {
        self.snapshot = snapshot
    }
}

private final class MockChallengeProgressReporter: ChallengeProgressReporter {
    private(set) var reported: [Set<ChallengeIdentifier>] = []

    func reportAchievedChallenges(_ challengeIDs: Set<ChallengeIdentifier>) {
        guard challengeIDs.isEmpty == false else { return }
        reported.append(challengeIDs)
    }
}
