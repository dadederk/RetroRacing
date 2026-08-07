//
//  LeaderboardIDCatalogTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 01/03/2026.
//

import XCTest
@testable import RetroRacingShared

final class LeaderboardIDCatalogTests: XCTestCase {

    func testGivenIPhonePlatformWhenResolvingRapidThenReturnsIPhoneRapidID() {
        // Given
        let difficulty: GameDifficulty = .rapid

        // When
        let leaderboardID = LeaderboardIDCatalog.leaderboardID(platform: .iPhone, difficulty: difficulty)

        // Then
        XCTAssertEqual(leaderboardID, "bestios001test")
    }

    func testGivenWatchOSPlatformWhenResolvingAllSpeedsThenReturnsExpectedIDs() {
        // Given
        let cruise: GameDifficulty = .cruise
        let fast: GameDifficulty = .fast
        let rapid: GameDifficulty = .rapid

        // When
        let cruiseID = LeaderboardIDCatalog.leaderboardID(platform: .watchOS, difficulty: cruise)
        let fastID = LeaderboardIDCatalog.leaderboardID(platform: .watchOS, difficulty: fast)
        let rapidID = LeaderboardIDCatalog.leaderboardID(platform: .watchOS, difficulty: rapid)

        // Then
        XCTAssertEqual(cruiseID, "bestwatchos001cruise")
        XCTAssertEqual(fastID, "bestwatchos001fast")
        XCTAssertEqual(rapidID, "bestwatchos001test")
    }

    func testGivenVisionOSPlatformWhenResolvingAllSpeedsThenReturnsExpectedIDs() {
        // Given
        let cruise: GameDifficulty = .cruise
        let fast: GameDifficulty = .fast
        let rapid: GameDifficulty = .rapid

        // When
        let cruiseID = LeaderboardIDCatalog.leaderboardID(platform: .visionOS, difficulty: cruise)
        let fastID = LeaderboardIDCatalog.leaderboardID(platform: .visionOS, difficulty: fast)
        let rapidID = LeaderboardIDCatalog.leaderboardID(platform: .visionOS, difficulty: rapid)

        // Then
        XCTAssertEqual(cruiseID, "bestvisionos001cruise")
        XCTAssertEqual(fastID, "bestvisionos001fast")
        XCTAssertEqual(rapidID, "bestvisionos001test")
    }
}
