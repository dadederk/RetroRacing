//
//  UserDefaultsChallengeProgressStoreTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 01/03/2026.
//

import XCTest
@testable import RetroRacingShared

final class UserDefaultsChallengeProgressStoreTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var suiteName: String!
    private var store: UserDefaultsChallengeProgressStore!

    override func setUp() {
        super.setUp()
        suiteName = "test.challengeprogressstore.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        store = UserDefaultsChallengeProgressStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        if let suiteName {
            UserDefaults().removePersistentDomain(forName: suiteName)
        }
        store = nil
        userDefaults = nil
        suiteName = nil
        super.tearDown()
    }

    func testGivenNoPersistedDataWhenLoadingThenReturnsEmptySnapshot() {
        // Given
        XCTAssertNotNil(store)

        // When
        let snapshot = store.load()

        // Then
        XCTAssertEqual(snapshot, .empty)
    }

    func testGivenSnapshotWhenSavingThenLoadReturnsSavedSnapshot() {
        // Given
        let snapshot = ChallengeProgressSnapshot(
            bestRunOvertakes: 420,
            cumulativeOvertakes: 1_337,
            lifetimeUsedControls: [.tap, .voiceOver],
            achievedChallengeIDs: [.runOvertakes100, .controlTap],
            backfillVersion: 1
        )

        // When
        store.save(snapshot)
        let loaded = store.load()

        // Then
        XCTAssertEqual(loaded, snapshot)
    }
}
