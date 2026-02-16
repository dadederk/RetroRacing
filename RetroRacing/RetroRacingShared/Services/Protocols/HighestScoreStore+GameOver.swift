//
//  HighestScoreStore+GameOver.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 16/02/2026.
//

import Foundation

/// Snapshot of game-over scoring details used by game-over UI.
public struct GameOverScoreSummary: Sendable {
    public let score: Int
    public let bestScore: Int
    public let isNewRecord: Bool
    public let previousBestScore: Int?

    public init(score: Int, bestScore: Int, isNewRecord: Bool, previousBestScore: Int?) {
        self.score = score
        self.bestScore = bestScore
        self.isNewRecord = isNewRecord
        self.previousBestScore = previousBestScore
    }
}

public extension HighestScoreStore {
    /// Evaluates and persists a game-over score against the current local best.
    func evaluateGameOverScore(_ score: Int) -> GameOverScoreSummary {
        let previousBestScore = currentBest()
        let isNewRecord = updateIfHigher(score)
        let bestScore = currentBest()
        return GameOverScoreSummary(
            score: score,
            bestScore: bestScore,
            isNewRecord: isNewRecord,
            previousBestScore: isNewRecord ? previousBestScore : nil
        )
    }
}
