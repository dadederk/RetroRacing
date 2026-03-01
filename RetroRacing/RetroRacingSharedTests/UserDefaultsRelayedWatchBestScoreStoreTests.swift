//
//  UserDefaultsRelayedWatchBestScoreStoreTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 01/03/2026.
//

import XCTest
@testable import RetroRacingShared

final class UserDefaultsRelayedWatchBestScoreStoreTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var store: UserDefaultsRelayedWatchBestScoreStore!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: "UserDefaultsRelayedWatchBestScoreStoreTests")
        userDefaults.removePersistentDomain(forName: "UserDefaultsRelayedWatchBestScoreStoreTests")
        store = UserDefaultsRelayedWatchBestScoreStore(
            userDefaults: userDefaults,
            keyPrefix: "watchRelayPendingBestScoreTests"
        )
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: "UserDefaultsRelayedWatchBestScoreStoreTests")
        store = nil
        userDefaults = nil
        super.tearDown()
    }

    func testGivenNoPendingScoreWhenReadingThenReturnsNil() {
        // Given
        let difficulty: GameDifficulty = .rapid

        // When
        let pending = store.pendingBestScore(for: difficulty)

        // Then
        XCTAssertNil(pending)
    }

    func testGivenHigherIncomingScoreWhenUpdatingThenPendingIsReplaced() {
        // Given
        _ = store.updatePendingBestScoreIfHigher(50, for: .rapid)

        // When
        let didUpdate = store.updatePendingBestScoreIfHigher(70, for: .rapid)
        let pending = store.pendingBestScore(for: .rapid)

        // Then
        XCTAssertTrue(didUpdate)
        XCTAssertEqual(pending, 70)
    }

    func testGivenLowerIncomingScoreWhenUpdatingThenPendingRemainsUnchanged() {
        // Given
        _ = store.updatePendingBestScoreIfHigher(90, for: .rapid)

        // When
        let didUpdate = store.updatePendingBestScoreIfHigher(40, for: .rapid)
        let pending = store.pendingBestScore(for: .rapid)

        // Then
        XCTAssertFalse(didUpdate)
        XCTAssertEqual(pending, 90)
    }

    func testGivenPendingScoresAcrossSpeedsWhenListingPendingDifficultiesThenReturnsOnlyStoredSpeeds() {
        // Given
        _ = store.updatePendingBestScoreIfHigher(80, for: .rapid)
        _ = store.updatePendingBestScoreIfHigher(40, for: .cruise)

        // When
        let pendingDifficulties = Set(store.pendingDifficulties())

        // Then
        XCTAssertEqual(pendingDifficulties, Set([.rapid, .cruise]))
    }
}
