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
            usedControls: [.tap, .voiceOver]
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
