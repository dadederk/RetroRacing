//
//  BestScoreSyncService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 16/02/2026.
//

import Foundation

/// Synchronizes the local highest score store with the best score from Game Center when available.
public final class BestScoreSyncService {
    private let leaderboardService: LeaderboardService
    private let highestScoreStore: HighestScoreStore

    public init(leaderboardService: LeaderboardService, highestScoreStore: HighestScoreStore) {
        self.leaderboardService = leaderboardService
        self.highestScoreStore = highestScoreStore
    }

    public func syncIfPossible() async {
        guard let remoteBestScore = await leaderboardService.fetchLocalPlayerBestScore() else {
            AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 Remote best score unavailable; keeping local best")
            return
        }
        highestScoreStore.syncFromRemote(bestScore: remoteBestScore)
        AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 Synced local best score from Game Center: \(remoteBestScore)")
    }
}
