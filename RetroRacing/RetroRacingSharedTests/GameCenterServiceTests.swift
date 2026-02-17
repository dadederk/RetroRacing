//
//  GameCenterServiceTests.swift
//  RetroRacingSharedTests
//

import XCTest
@testable import RetroRacingShared

final class GameCenterServiceTests: XCTestCase {

    func testConfigurationReturnsInjectedLeaderboardID() {
        // Given
        let mockConfig = MockLeaderboardConfiguration(
            cruiseLeaderboardID: "test_cruise_001",
            fastLeaderboardID: "test_fast_001",
            rapidLeaderboardID: "test_rapid_001"
        )

        // When
        _ = GameCenterService(configuration: mockConfig, isDebugBuild: false)

        // Then
        XCTAssertEqual(mockConfig.leaderboardID(for: .cruise), "test_cruise_001")
        XCTAssertEqual(mockConfig.leaderboardID(for: .fast), "test_fast_001")
        XCTAssertEqual(mockConfig.leaderboardID(for: .rapid), "test_rapid_001")
    }

    func testServiceCreatedWithMockConfigurationDoesNotCrash() {
        // Given
        let mockConfig = MockLeaderboardConfiguration(leaderboardID: "test123")

        // When
        _ = GameCenterService(configuration: mockConfig, isDebugBuild: false).isAuthenticated()

        // Then
        // In test/simulator, typically not authenticated; just ensure no crash.
    }

    func testSubmitScoreWhenNotAuthenticatedDoesNotCrash() {
        // Given
        let mockConfig = MockLeaderboardConfiguration(leaderboardID: "test123")
        let service = GameCenterService(configuration: mockConfig, isDebugBuild: false)

        // When
        service.submitScore(100, difficulty: .rapid)

        // Then
        // Guard in submitScore prevents GKLeaderboard call when !isAuthenticated; no crash.
    }

    func testGivenDebugBuildWhenCheckingScoreSubmissionEligibilityThenSubmissionIsDisabled() {
        // Given
        let service = GameCenterService(
            configuration: MockLeaderboardConfiguration(leaderboardID: "test123"),
            isDebugBuild: true
        )

        // When
        let isScoreSubmissionEnabled = service.isScoreSubmissionEnabled

        // Then
        XCTAssertFalse(isScoreSubmissionEnabled)
    }

    func testGivenReleaseBuildWhenCheckingScoreSubmissionEligibilityThenSubmissionIsEnabled() {
        // Given
        let service = GameCenterService(
            configuration: MockLeaderboardConfiguration(leaderboardID: "test123"),
            isDebugBuild: false
        )

        // When
        let isScoreSubmissionEnabled = service.isScoreSubmissionEnabled

        // Then
        XCTAssertTrue(isScoreSubmissionEnabled)
    }
}
