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
            highestScoreStore: highestScoreStore
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
        _ = highestScoreStore.updateIfHigher(40)
        leaderboardService.remoteBestScore = 75

        // When
        await syncService.syncIfPossible()

        // Then
        XCTAssertEqual(highestScoreStore.currentBest(), 75)
    }

    func testGivenRemoteBestUnavailableWhenSyncingThenLocalBestStaysUnchanged() async {
        // Given
        _ = highestScoreStore.updateIfHigher(40)
        leaderboardService.remoteBestScore = nil

        // When
        await syncService.syncIfPossible()

        // Then
        XCTAssertEqual(highestScoreStore.currentBest(), 40)
    }
}
