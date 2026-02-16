//
//  GameState.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// Mutable gameplay snapshot tracking progression, pause state, and scoring.
public struct GameState {
    /// Points per level; must match the divisor used for `level` in score's didSet.
    public static let levelStep = 100
    /// Default number of points before level-up to show the speed-increasing alert.
    public static let defaultSpeedAlertWindowPoints = 3

    public private(set) var level = 1
    public var isPaused = false
    public var lives = 3
    public var score = 0 {
        didSet {
            level = (score / Self.levelStep) + 1
        }
    }

    /// Returns true when the next score tick(s) could cross the next level boundary (same rule as level).
    /// - Parameters:
    ///   - score: Current score.
    ///   - windowPoints: Number of points before level-up to consider "imminent"; defaults to `defaultSpeedAlertWindowPoints`.
    public static func isLevelChangeImminent(score: Int, windowPoints: Int = defaultSpeedAlertWindowPoints) -> Bool {
        let threshold = levelStep - windowPoints
        guard score >= threshold else { return false }
        let pointsInCurrentLevel = score % levelStep
        return pointsInCurrentLevel >= threshold
    }

    /// Returns the update offset (0-based) where score reaches the next level boundary using upcoming row points.
    /// Offset `0` means "current update", `1` means "next update", and so on.
    public static func updatesUntilNextLevelChange(score: Int, upcomingRowPoints: [Int]) -> Int? {
        let nextLevelScore = ((score / levelStep) + 1) * levelStep
        guard score < nextLevelScore else { return nil }

        var projectedScore = score
        for (offset, points) in upcomingRowPoints.enumerated() {
            projectedScore += max(0, points)
            if projectedScore >= nextLevelScore {
                return offset
            }
        }
        return nil
    }
}
