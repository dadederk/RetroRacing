//
//  LeaderboardService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// Contract for submitting leaderboard scores and checking authentication state.
public protocol LeaderboardService {
    func submitScore(_ score: Int, difficulty: GameDifficulty)
    func isAuthenticated() -> Bool
    /// Returns the authenticated local player's all-time best score for the leaderboard mapped to the given speed.
    /// Returns `nil` when unavailable (for example unauthenticated, offline, or no entry yet).
    func fetchLocalPlayerBestScore(for difficulty: GameDifficulty) async -> Int?
}

public extension LeaderboardService {
    func submitScore(_ score: Int) {
        submitScore(score, difficulty: .defaultDifficulty)
    }

    func fetchLocalPlayerBestScore() async -> Int? {
        await fetchLocalPlayerBestScore(for: .defaultDifficulty)
    }
}
