//
//  LeaderboardConfigurationUniversal.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import RetroRacingShared

/// Game Center leaderboard configuration for the universal Apple platforms target.
struct LeaderboardConfigurationUniversal: LeaderboardConfiguration {
    func leaderboardID(for difficulty: GameDifficulty) -> String {
        LeaderboardIDCatalog.leaderboardID(platform: .iPhone, difficulty: difficulty)
    }
}
