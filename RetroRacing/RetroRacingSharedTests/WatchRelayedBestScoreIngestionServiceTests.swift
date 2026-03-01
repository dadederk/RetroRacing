//
//  WatchRelayedBestScoreIngestionServiceTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 01/03/2026.
//

import XCTest
@testable import RetroRacingShared

final class WatchRelayedBestScoreIngestionServiceTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var pendingStore: UserDefaultsRelayedWatchBestScoreStore!
    private var leaderboardService: MockLeaderboardService!
    private var ingestionService: WatchRelayedBestScoreIngestionService!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "WatchRelayedBestScoreIngestionServiceTests")
        userDefaults.removePersistentDomain(forName: "WatchRelayedBestScoreIngestionServiceTests")
        pendingStore = UserDefaultsRelayedWatchBestScoreStore(
            userDefaults: userDefaults,
            keyPrefix: "watchRelayPendingBestScoreIngestionTests"
        )
        leaderboardService = MockLeaderboardService()
        ingestionService = WatchRelayedBestScoreIngestionService(
            leaderboardService: leaderboardService,
            pendingStore: pendingStore
        )
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "WatchRelayedBestScoreIngestionServiceTests")
        ingestionService = nil
        leaderboardService = nil
        pendingStore = nil
        userDefaults = nil
        super.tearDown()
    }

    func testGivenHigherScoreWhenIngestingThenPendingBestIsStored() {
        // Given
        let score = 100
        let difficulty: GameDifficulty = .rapid

        // When
        let didUpdate = ingestionService.ingest(score: score, difficulty: difficulty)

        // Then
        XCTAssertTrue(didUpdate)
        XCTAssertEqual(pendingStore.pendingBestScore(for: difficulty), 100)
    }

    func testGivenLowerScoreWhenIngestingThenPendingBestRemainsHigherValue() {
        // Given
        _ = ingestionService.ingest(score: 100, difficulty: .rapid)

        // When
        let didUpdate = ingestionService.ingest(score: 70, difficulty: .rapid)

        // Then
        XCTAssertFalse(didUpdate)
        XCTAssertEqual(pendingStore.pendingBestScore(for: .rapid), 100)
    }

    func testGivenPendingScoreWhenFlushingAndRemoteBestVerifiesThenPendingIsCleared() async {
        // Given
        _ = ingestionService.ingest(score: 120, difficulty: .rapid)
        leaderboardService.authenticated = true
        leaderboardService.remoteBestScoresByDifficulty[.rapid] = 120

        // When
        await ingestionService.flushPendingIfPossible(trigger: .relayReceived)

        // Then
        XCTAssertEqual(leaderboardService.submittedScores, [120])
        XCTAssertEqual(leaderboardService.submittedDifficulties, [.rapid])
        XCTAssertNil(pendingStore.pendingBestScore(for: .rapid))
    }

    func testGivenPendingScoreWhenFlushingAndRemoteBestUnavailableThenPendingIsKept() async {
        // Given
        _ = ingestionService.ingest(score: 120, difficulty: .rapid)
        leaderboardService.authenticated = true
        leaderboardService.remoteBestScoresByDifficulty[.rapid] = nil

        // When
        await ingestionService.flushPendingIfPossible(trigger: .relayReceived)

        // Then
        XCTAssertEqual(leaderboardService.submittedScores, [120])
        XCTAssertEqual(pendingStore.pendingBestScore(for: .rapid), 120)
    }

    func testGivenPendingScoreWhenFlushingAndPlayerNotAuthenticatedThenSubmissionIsSkipped() async {
        // Given
        _ = ingestionService.ingest(score: 75, difficulty: .fast)
        leaderboardService.authenticated = false

        // When
        await ingestionService.flushPendingIfPossible(trigger: .appLifecycle)

        // Then
        XCTAssertTrue(leaderboardService.submittedScores.isEmpty)
        XCTAssertEqual(pendingStore.pendingBestScore(for: .fast), 75)
    }
}
