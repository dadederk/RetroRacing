//
//  GameCenterServiceTests.swift
//  RetroRacingSharedTests
//

import XCTest
@testable import RetroRacingShared

final class GameCenterServiceTests: XCTestCase {

    func testConfigurationReturnsInjectedLeaderboardID() {
        let mockConfig = MockLeaderboardConfiguration(
            cruiseLeaderboardID: "test_cruise_001",
            fastLeaderboardID: "test_fast_001",
            rapidLeaderboardID: "test_rapid_001"
        )
        _ = GameCenterService(configuration: mockConfig)
        XCTAssertEqual(mockConfig.leaderboardID(for: .cruise), "test_cruise_001")
        XCTAssertEqual(mockConfig.leaderboardID(for: .fast), "test_fast_001")
        XCTAssertEqual(mockConfig.leaderboardID(for: .rapid), "test_rapid_001")
    }

    func testServiceCreatedWithMockConfigurationDoesNotCrash() {
        let mockConfig = MockLeaderboardConfiguration(leaderboardID: "test123")
        _ = GameCenterService(configuration: mockConfig).isAuthenticated()
        // In test/simulator, typically not authenticated; just ensure no crash.
    }

    func testSubmitScoreWhenNotAuthenticatedDoesNotCrash() {
        let mockConfig = MockLeaderboardConfiguration(leaderboardID: "test123")
        let service = GameCenterService(configuration: mockConfig)
        service.submitScore(100, difficulty: .rapid)
        // Guard in submitScore prevents GKLeaderboard call when !isAuthenticated; no crash.
    }
}
