//
//  WatchRelayedBestScoreIngestionService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

public enum WatchRelayFlushTrigger: String, Sendable {
    case relayReceived
    case appLifecycle
    case gameCenterAuthChanged
}

/// Ingests watch-relayed best scores and performs single-shot flush attempts on natural triggers.
public final class WatchRelayedBestScoreIngestionService {
    private let leaderboardService: LeaderboardService
    private let pendingStore: RelayedWatchBestScoreStore

    public init(
        leaderboardService: LeaderboardService,
        pendingStore: RelayedWatchBestScoreStore
    ) {
        self.leaderboardService = leaderboardService
        self.pendingStore = pendingStore
    }

    /// Stores a relayed score if it improves the pending max for that speed.
    @discardableResult
    public func ingest(score: Int, difficulty: GameDifficulty) -> Bool {
        let updated = pendingStore.updatePendingBestScoreIfHigher(score, for: difficulty)
        if updated {
            AppLog.info(
                AppLog.game + AppLog.leaderboard,
                "🏆 Stored relayed watch best score \(score) for speed \(difficulty.rawValue)"
            )
        } else {
            AppLog.info(
                AppLog.game + AppLog.leaderboard,
                "🏆 Ignored relayed watch score \(score) for speed \(difficulty.rawValue) (pending max already higher/equal)"
            )
        }
        return updated
    }

    /// Performs one flush pass for all pending difficulties; no loops or timer-based retries.
    public func flushPendingIfPossible(trigger: WatchRelayFlushTrigger) async {
        let pendingDifficulties = pendingStore.pendingDifficulties()
        guard pendingDifficulties.isEmpty == false else { return }

        guard leaderboardService.isAuthenticated() else {
            AppLog.info(
                AppLog.game + AppLog.leaderboard,
                "🏆 Skipped relayed watch score flush (\(trigger.rawValue)) – iPhone player not authenticated"
            )
            return
        }

        for difficulty in pendingDifficulties {
            guard let pendingScore = pendingStore.pendingBestScore(for: difficulty) else {
                continue
            }

            AppLog.info(
                AppLog.game + AppLog.leaderboard,
                "🏆 Flushing relayed watch best \(pendingScore) for speed \(difficulty.rawValue) (\(trigger.rawValue))"
            )
            leaderboardService.submitScore(pendingScore, difficulty: difficulty)

            guard let remoteBestScore = await leaderboardService.fetchLocalPlayerBestScore(for: difficulty) else {
                AppLog.info(
                    AppLog.game + AppLog.leaderboard,
                    "🏆 Relayed watch best verification unavailable for speed \(difficulty.rawValue); keeping pending"
                )
                continue
            }

            if remoteBestScore >= pendingScore {
                pendingStore.clearPendingBestScore(for: difficulty)
                AppLog.info(
                    AppLog.game + AppLog.leaderboard,
                    "🏆 Verified relayed watch best \(pendingScore) for speed \(difficulty.rawValue); cleared pending"
                )
            } else {
                AppLog.info(
                    AppLog.game + AppLog.leaderboard,
                    "🏆 Relayed watch best \(pendingScore) not yet reflected remotely (remote: \(remoteBestScore)); keeping pending"
                )
            }
        }
    }
}
