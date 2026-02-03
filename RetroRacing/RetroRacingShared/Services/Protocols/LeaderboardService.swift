//
//  LeaderboardService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// Contract for submitting leaderboard scores and checking authentication state.
public protocol LeaderboardService {
    func submitScore(_ score: Int)
    func isAuthenticated() -> Bool
}
