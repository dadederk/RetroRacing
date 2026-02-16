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
    private let difficultyProvider: () -> GameDifficulty

    public init(
        leaderboardService: LeaderboardService,
        highestScoreStore: HighestScoreStore,
        difficultyProvider: @escaping () -> GameDifficulty
    ) {
        self.leaderboardService = leaderboardService
        self.highestScoreStore = highestScoreStore
        self.difficultyProvider = difficultyProvider
    }

    public func syncIfPossible() async {
        let difficulty = difficultyProvider()
        guard let remoteBestScore = await leaderboardService.fetchLocalPlayerBestScore(for: difficulty) else {
            AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 Remote best score unavailable; keeping local best")
            return
        }
        highestScoreStore.syncFromRemote(bestScore: remoteBestScore, for: difficulty)
        AppLog.info(
            AppLog.game + AppLog.leaderboard,
            "🏆 Synced local best score from Game Center: \(remoteBestScore) for speed \(difficulty.rawValue)"
        )
    }
}
