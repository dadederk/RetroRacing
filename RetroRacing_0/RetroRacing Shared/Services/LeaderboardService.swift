//
//  LeaderboardService.swift
//  RetroRacing
//
//  Created by Dani on 30/01/2026.
//

import Foundation

protocol LeaderboardService {
    func submitScore(_ score: Int)
    func isAuthenticated() -> Bool
}
