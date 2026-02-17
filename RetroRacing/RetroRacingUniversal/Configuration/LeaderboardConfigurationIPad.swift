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
        switch difficulty {
        case .cruise:
            return "bestipad001cruise"
        case .fast:
            return "bestipad001fast"
        case .rapid:
            return "bestipad001test"
        @unknown default:
            return "bestipad001test"
        }
    }
}
