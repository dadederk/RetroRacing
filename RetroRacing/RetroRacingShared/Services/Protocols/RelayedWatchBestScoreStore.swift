//
//  RelayedWatchBestScoreStore.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Persistence contract for watch best scores waiting for iPhone Game Center verification.
public protocol RelayedWatchBestScoreStore {
    func pendingBestScore(for difficulty: GameDifficulty) -> Int?
    @discardableResult
    func updatePendingBestScoreIfHigher(_ score: Int, for difficulty: GameDifficulty) -> Bool
    func clearPendingBestScore(for difficulty: GameDifficulty)
    func pendingDifficulties() -> [GameDifficulty]
}
