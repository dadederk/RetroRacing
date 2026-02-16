//
//  HighestScoreStore.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// Abstraction for persisting and querying the user's personal best score.
/// Implementations must be side-effect free except for storage writes and must be thread-safe.
public protocol HighestScoreStore {
    /// Returns the current best score stored locally.
    func currentBest(for difficulty: GameDifficulty) -> Int

    /// Stores the score when it is strictly greater than the current best.
    /// - Returns: `true` when the score became the new best.
    @discardableResult
    func updateIfHigher(_ score: Int, for difficulty: GameDifficulty) -> Bool

    /// Optional: syncs the local best from a remote source (e.g. Game Center leaderboard best).
    /// Should overwrite when the remote score is greater than the local best.
    func syncFromRemote(bestScore: Int, for difficulty: GameDifficulty)
}

public extension HighestScoreStore {
    func currentBest() -> Int {
        currentBest(for: .defaultDifficulty)
    }

    @discardableResult
    func updateIfHigher(_ score: Int) -> Bool {
        updateIfHigher(score, for: .defaultDifficulty)
    }

    func syncFromRemote(bestScore: Int) {
        syncFromRemote(bestScore: bestScore, for: .defaultDifficulty)
    }
}
