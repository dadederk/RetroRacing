//
//  ScreenshotCaptureServices.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 18/10/2026.
//

import GameKit

public enum ScreenshotCaptureServices {
    public static func makeGameCenterService(
        configuration: LeaderboardConfiguration
    ) -> GameCenterService {
        GameCenterService(
            configuration: configuration,
            friendSnapshotService: ScreenshotNoOpFriendSnapshotService(),
            authenticationPresenter: nil,
            authenticateHandlerSetter: nil,
            isDebugBuild: true,
            allowDebugScoreSubmission: false,
            isAuthenticatedProvider: { false },
            pendingScoreStore: nil
        )
    }
}

private struct ScreenshotNoOpFriendSnapshotService: GameCenterFriendSnapshotServicing {
    func fetchFriendSnapshot(
        from leaderboard: GKLeaderboard,
        remoteBestScore: Int?
    ) async -> FriendLeaderboardSnapshot? {
        nil
    }
}
