//
//  GameViewState.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import Foundation

/// Bundles HUD-related state for clarity and predictable updates.
struct HUDState {
    var score: Int = 0
    var lives: Int = GameState.initialLives
    var showGameOver: Bool = false
    var gameOverScore: Int = 0
    var gameOverBestScore: Int = 0
    var gameOverDifficulty: GameDifficulty = .defaultDifficulty
    var gameOverPreviousBestScore: Int?
    var gameOverNextFriendAhead: GameOverFriendAheadSummary?
    var gameOverOvertakenFriends = [GameOverOvertakenFriendSummary]()
    var gameOverNewlyAchievedAchievementIDs = [AchievementIdentifier]()
    var isNewHighScore: Bool = false
    var shouldRequestRatingOnGameOverModal = false
    /// True when the delegate reported that a level change is imminent (last few points before level-up).
    var speedIncreaseImminent: Bool = false
}

/// Stable social recap captured for a finished SharePlay round.
struct GameOverSocialStatsSummary: Sendable, Equatable {
    var nextFriendAhead: GameOverFriendAheadSummary?
    var overtakenFriends = [GameOverOvertakenFriendSummary]()
}

/// Tracks pause states separately from HUD to avoid unrelated view updates.
struct PauseState {
    var scenePaused: Bool = false     // reflects scene state (crash/start pauses)
    var isUserPaused: Bool = false    // user-requested pause state
    var isHingePaused: Bool = false

    var showsResume: Bool {
        isUserPaused || isHingePaused
    }

    /// True only when the current pause comes from an explicit user pause request.
    var isExplicitUserPauseActive: Bool {
        scenePaused && isUserPaused
    }

    var pauseButtonDisabled: Bool {
        scenePaused && showsResume == false
    }
}

/// Requires sustained directional travel before treating an available hinge as moving.
struct HingeMotionDetector {
    private var lastAngleDegrees: Double?
    private var candidateStartAngleDegrees: Double?
    private var candidateStartUptime: TimeInterval?
    private var candidateDirection: FloatingPointSign?
    private var candidateStepCount = 0
    private(set) var isMoving = false
    static let minimumStepDegrees = 1.0
    static let movementThresholdDegrees = 10.0
    static let movementWindowSeconds = 0.5

    mutating func observe(angleDegrees: Double?, at uptime: TimeInterval) -> Bool {
        guard let angleDegrees, angleDegrees.isFinite, (0...180).contains(angleDegrees),
              uptime.isFinite else {
            reset()
            return false
        }
        guard let lastAngleDegrees else {
            self.lastAngleDegrees = angleDegrees
            return false
        }
        self.lastAngleDegrees = angleDegrees
        let step = angleDegrees - lastAngleDegrees
        guard abs(step) >= Self.minimumStepDegrees else {
            return false
        }

        if isMoving { return true }

        if candidateDirection != step.sign ||
           uptime - (candidateStartUptime ?? uptime) > Self.movementWindowSeconds ||
           uptime < (candidateStartUptime ?? uptime) {
            candidateStartAngleDegrees = lastAngleDegrees
            candidateStartUptime = uptime
            candidateDirection = step.sign
            candidateStepCount = 0
        }
        candidateStepCount += 1
        guard candidateStepCount >= 2,
              let candidateStartAngleDegrees,
              abs(angleDegrees - candidateStartAngleDegrees) >= Self.movementThresholdDegrees else {
            return false
        }
        isMoving = true
        return true
    }

    mutating func settle() {
        isMoving = false
        candidateStartAngleDegrees = nil
        candidateStartUptime = nil
        candidateDirection = nil
        candidateStepCount = 0
    }

    private mutating func reset() {
        lastAngleDegrees = nil
        settle()
    }
}

/// Handles transient control visuals and their timers.
struct ControlState {
    var leftButtonDown: Bool = false
    var rightButtonDown: Bool = false
    var leftFlashTask: Task<Void, Never>?
    var rightFlashTask: Task<Void, Never>?

    mutating func cancelFlashTasks() {
        leftFlashTask?.cancel()
        rightFlashTask?.cancel()
        leftFlashTask = nil
        rightFlashTask = nil
    }
}

enum ControlSide {
    case left
    case right
}
