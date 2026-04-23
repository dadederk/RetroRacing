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
                AppLog.leaderboard + AppLog.lifecycle,
                "WATCH_RELAY_INGEST",
                outcome: .succeeded,
                fields: [
                    .int("score", score),
                    .string("speed", difficulty.rawValue)
                ]
            )
        } else {
            AppLog.info(
                AppLog.leaderboard + AppLog.lifecycle,
                "WATCH_RELAY_INGEST",
                outcome: .ignored,
                fields: [
                    .reason("pending_score_already_higher_or_equal"),
                    .int("score", score),
                    .string("speed", difficulty.rawValue)
                ]
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
                AppLog.leaderboard + AppLog.lifecycle,
                "WATCH_RELAY_FLUSH",
                outcome: .blocked,
                fields: [
                    .reason("player_not_authenticated"),
                    .string("trigger", trigger.rawValue)
                ]
            )
            return
        }

        for difficulty in pendingDifficulties {
            guard let pendingScore = pendingStore.pendingBestScore(for: difficulty) else {
                continue
            }

            AppLog.info(
                AppLog.leaderboard + AppLog.lifecycle,
                "WATCH_RELAY_FLUSH",
                outcome: .started,
                fields: [
                    .int("pendingScore", pendingScore),
                    .string("speed", difficulty.rawValue),
                    .string("trigger", trigger.rawValue)
                ]
            )
            leaderboardService.submitScore(pendingScore, difficulty: difficulty)

            guard let remoteBestScore = await leaderboardService.fetchLocalPlayerBestScore(for: difficulty) else {
                AppLog.info(
                    AppLog.leaderboard + AppLog.lifecycle,
                    "WATCH_RELAY_FLUSH",
                    outcome: .deferred,
                    fields: [
                        .reason("remote_best_unavailable"),
                        .int("pendingScore", pendingScore),
                        .string("speed", difficulty.rawValue)
                    ]
                )
                continue
            }

            if remoteBestScore >= pendingScore {
                pendingStore.clearPendingBestScore(for: difficulty)
                AppLog.info(
                    AppLog.leaderboard + AppLog.lifecycle,
                    "WATCH_RELAY_FLUSH",
                    outcome: .succeeded,
                    fields: [
                        .int("pendingScore", pendingScore),
                        .int("remoteBest", remoteBestScore),
                        .string("speed", difficulty.rawValue)
                    ]
                )
            } else {
                AppLog.warning(
                    AppLog.leaderboard + AppLog.lifecycle,
                    "WATCH_RELAY_FLUSH",
                    outcome: .deferred,
                    fields: [
                        .reason("remote_best_lower_than_pending"),
                        .int("pendingScore", pendingScore),
                        .int("remoteBest", remoteBestScore),
                        .string("speed", difficulty.rawValue)
                    ]
                )
            }
        }
    }
}
