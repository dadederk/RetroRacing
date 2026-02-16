//
//  BestScoreSyncServiceTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 16/02/2026.
//

import XCTest
@testable import RetroRacingShared

final class BestScoreSyncServiceTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var suiteName: String!
    private var highestScoreStore: UserDefaultsHighestScoreStore!
    private var leaderboardService: MockLeaderboardService!
    private var syncService: BestScoreSyncService!

    override func setUp() {
        super.setUp()
        suiteName = "test.bestscoresync.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        highestScoreStore = UserDefaultsHighestScoreStore(userDefaults: userDefaults)
        leaderboardService = MockLeaderboardService()
        syncService = BestScoreSyncService(
            leaderboardService: leaderboardService,
            highestScoreStore: highestScoreStore,
            difficultyProvider: { .rapid }
        )
    }

    override func tearDown() {
        if let suiteName {
            UserDefaults().removePersistentDomain(forName: suiteName)
        }
        syncService = nil
        leaderboardService = nil
        highestScoreStore = nil
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testGivenRemoteBestHigherWhenSyncingThenLocalBestIsUpdated() async {
        // Given
        _ = highestScoreStore.updateIfHigher(40, for: .rapid)
        leaderboardService.remoteBestScoresByDifficulty[.rapid] = 75

        // When
        await syncService.syncIfPossible()

        // Then
        XCTAssertEqual(highestScoreStore.currentBest(for: .rapid), 75)
    }

    func testGivenRemoteBestUnavailableWhenSyncingThenLocalBestStaysUnchanged() async {
        // Given
        _ = highestScoreStore.updateIfHigher(40, for: .rapid)
        leaderboardService.remoteBestScoresByDifficulty[.rapid] = nil

        // When
        await syncService.syncIfPossible()

        // Then
        XCTAssertEqual(highestScoreStore.currentBest(for: .rapid), 40)
    }
}
