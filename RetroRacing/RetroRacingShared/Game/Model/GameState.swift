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
    public static let defaultSpeedAlertWindowPoints = 5

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
}
