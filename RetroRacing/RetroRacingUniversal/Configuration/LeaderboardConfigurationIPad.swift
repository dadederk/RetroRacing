//
//  LeaderboardConfigurationIPad.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import RetroRacingShared

/// Game Center leaderboard configuration for iPadOS sandbox.
struct LeaderboardConfigurationIPad: LeaderboardConfiguration {
    func leaderboardID(for difficulty: GameDifficulty) -> String {
        LeaderboardIDCatalog.leaderboardID(platform: .iPad, difficulty: difficulty)
    }
}
