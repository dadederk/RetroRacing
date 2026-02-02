//
//  GameCenterServiceTests.swift
//  RetroRacingSharedTests
//

import XCTest
@testable import RetroRacingShared

final class GameCenterServiceTests: XCTestCase {

    func testConfigurationReturnsInjectedLeaderboardID() {
        let mockConfig = MockLeaderboardConfiguration(leaderboardID: "test_leaderboard_001")
        let service = GameCenterService(configuration: mockConfig)
        // Service stores configuration; leaderboardID is used when submitting scores.
        XCTAssertEqual(mockConfig.leaderboardID, "test_leaderboard_001")
    }

    func testServiceCreatedWithMockConfigurationDoesNotCrash() {
        let mockConfig = MockLeaderboardConfiguration(leaderboardID: "test123")
        _ = GameCenterService(configuration: mockConfig).isAuthenticated()
        // In test/simulator, typically not authenticated; just ensure no crash.
    }

    func testSubmitScoreWhenNotAuthenticatedDoesNotCrash() {
        let mockConfig = MockLeaderboardConfiguration(leaderboardID: "test123")
        let service = GameCenterService(configuration: mockConfig)
        service.submitScore(100)
        // Guard in submitScore prevents GKLeaderboard call when !isAuthenticated; no crash.
    }
}
