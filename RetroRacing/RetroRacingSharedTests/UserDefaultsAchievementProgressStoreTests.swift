//
//  UserDefaultsAchievementProgressStoreTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 01/03/2026.
//

import XCTest
@testable import RetroRacingShared

final class UserDefaultsAchievementProgressStoreTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var suiteName: String!
    private var store: UserDefaultsAchievementProgressStore!

    override func setUp() {
        super.setUp()
        suiteName = "test.achievementprogressstore.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        store = UserDefaultsAchievementProgressStore(userDefaults: userDefaults)
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
        let snapshot = AchievementProgressSnapshot(
            bestRunOvertakes: 420,
            cumulativeOvertakes: 1_337,
            lifetimeUsedControls: [.tap, .voiceOver],
            achievedAchievementIDs: [.runOvertakes100, .controlTap],
            backfillVersion: 1
        )

        // When
        store.save(snapshot)
        let loaded = store.load()

        // Then
        XCTAssertEqual(loaded, snapshot)
    }
}
