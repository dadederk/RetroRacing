//
//  PendingLeaderboardScoreStore.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 09/04/2026.
//

import Foundation

/// Persistence contract for leaderboard scores that could not be submitted because the
/// player was not authenticated at the time of the game over. Scores are held here until
/// `GameCenterService.flushPendingScoresIfPossible()` is called (typically on auth change
/// or app-lifecycle triggers). Only the best pending score per difficulty is retained.
public protocol PendingLeaderboardScoreStore: Sendable {
    func bestPendingScore(for difficulty: GameDifficulty) -> Int?
    @discardableResult
    func updatePendingBestScoreIfHigher(_ score: Int, for difficulty: GameDifficulty) -> Bool
    func clearPendingBestScore(for difficulty: GameDifficulty)
    func pendingDifficulties() -> [GameDifficulty]
}
