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
        _ = GameCenterService(
            configuration: mockConfig,
            friendSnapshotService: GameCenterFriendSnapshotService(avatarCache: GameCenterAvatarCache()),
            isDebugBuild: false,
            allowDebugScoreSubmission: false
        )

        // Then
        XCTAssertEqual(mockConfig.leaderboardID(for: .cruise), "test_cruise_001")
        XCTAssertEqual(mockConfig.leaderboardID(for: .fast), "test_fast_001")
        XCTAssertEqual(mockConfig.leaderboardID(for: .rapid), "test_rapid_001")
    }

    func testServiceCreatedWithMockConfigurationDoesNotCrash() {
        // Given
        let mockConfig = MockLeaderboardConfiguration(leaderboardID: "test123")

        // When
        _ = GameCenterService(
            configuration: mockConfig,
            friendSnapshotService: GameCenterFriendSnapshotService(avatarCache: GameCenterAvatarCache()),
            isDebugBuild: false,
            allowDebugScoreSubmission: false
        ).isAuthenticated()

        // Then
        // In test/simulator, typically not authenticated; just ensure no crash.
    }

    func testSubmitScoreWhenNotAuthenticatedDoesNotCrash() {
        // Given
        let mockConfig = MockLeaderboardConfiguration(leaderboardID: "test123")
        let service = GameCenterService(
            configuration: mockConfig,
            friendSnapshotService: GameCenterFriendSnapshotService(avatarCache: GameCenterAvatarCache()),
            isDebugBuild: false,
            allowDebugScoreSubmission: false
        )

        // When
        service.submitScore(100, difficulty: .rapid)

        // Then
        // Guard in submitScore prevents GKLeaderboard call when !isAuthenticated; no crash.
    }

    func testGivenDebugBuildWhenCheckingScoreSubmissionEligibilityThenSubmissionIsDisabled() {
        // Given
        let service = GameCenterService(
            configuration: MockLeaderboardConfiguration(leaderboardID: "test123"),
            friendSnapshotService: GameCenterFriendSnapshotService(avatarCache: GameCenterAvatarCache()),
            isDebugBuild: true,
            allowDebugScoreSubmission: false
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
            friendSnapshotService: GameCenterFriendSnapshotService(avatarCache: GameCenterAvatarCache()),
            isDebugBuild: false,
            allowDebugScoreSubmission: false
        )

        // When
        let isScoreSubmissionEnabled = service.isScoreSubmissionEnabled

        // Then
        XCTAssertTrue(isScoreSubmissionEnabled)
    }

    func testGivenDebugBuildAndDebugOverrideWhenCheckingScoreSubmissionEligibilityThenSubmissionIsEnabled() {
        // Given
        let service = GameCenterService(
            configuration: MockLeaderboardConfiguration(leaderboardID: "test123"),
            friendSnapshotService: GameCenterFriendSnapshotService(avatarCache: GameCenterAvatarCache()),
            isDebugBuild: true,
            allowDebugScoreSubmission: true
        )

        // When
        let isScoreSubmissionEnabled = service.isScoreSubmissionEnabled

        // Then
        XCTAssertTrue(isScoreSubmissionEnabled)
    }

    func testGivenPlayerIsNotAuthenticatedWhenFetchingFriendSnapshotThenReturnsNil() async {
        // Given
        let service = GameCenterService(
            configuration: MockLeaderboardConfiguration(leaderboardID: "test123"),
            friendSnapshotService: GameCenterFriendSnapshotService(avatarCache: GameCenterAvatarCache()),
            isDebugBuild: false,
            allowDebugScoreSubmission: false,
            isAuthenticatedProvider: { false }
        )

        // When
        let snapshot = await service.fetchFriendLeaderboardSnapshot(for: .rapid)

        // Then
        XCTAssertNil(snapshot)
    }

    func testGivenReporterWhenNoChallengesThenReportingDoesNothing() {
        // Given
        let reporter = GameCenterChallengeProgressReporter(isAuthenticatedProvider: { true })

        // When
        reporter.reportAchievedChallenges([])

        // Then
        // No crash and no Game Center call attempted.
    }

    func testGivenReporterWhenNotAuthenticatedThenReportingDoesNotCrash() {
        // Given
        let reporter = GameCenterChallengeProgressReporter(isAuthenticatedProvider: { false })

        // When
        reporter.reportAchievedChallenges([.controlTap, .eventGAADAssistive])

        // Then
        // No crash and reporting is skipped.
    }

    func testGivenDuplicateAndUnsortedFriendEntriesWhenNormalizingSnapshotThenFiltersAndSortsEntries() {
        // Given
        let entries = [
            FriendLeaderboardEntry(playerID: "p2", displayName: "Marta", score: 120),
            FriendLeaderboardEntry(playerID: "p1", displayName: "Alex", score: 80),
            FriendLeaderboardEntry(playerID: "p1", displayName: "Alex", score: 140),
            FriendLeaderboardEntry(playerID: "p3", displayName: "NoScore", score: 0),
            FriendLeaderboardEntry(playerID: "", displayName: "MissingID", score: 90)
        ]

        // When
        let snapshot = GameCenterService.normalizedFriendSnapshot(
            remoteBestScore: 100,
            entries: entries
        )

        // Then
        XCTAssertEqual(snapshot?.remoteBestScore, 100)
        XCTAssertEqual(snapshot?.friendEntries.map(\.playerID), ["p2", "p1"])
        XCTAssertEqual(snapshot?.friendEntries.map(\.score), [120, 140])
    }
}
