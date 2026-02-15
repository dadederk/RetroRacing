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
    var lives: Int = 3
    var showGameOver: Bool = false
    var gameOverScore: Int = 0
    var isNewHighScore: Bool = false
    /// True when the delegate reported that a level change is imminent (last few points before level-up).
    var speedIncreaseImminent: Bool = false
}

/// Tracks pause states separately from HUD to avoid unrelated view updates.
struct PauseState {
    var scenePaused: Bool = false     // reflects scene state (crash/start pauses)
    var isUserPaused: Bool = false    // user-requested pause state

    var pauseButtonDisabled: Bool {
        scenePaused && isUserPaused == false
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
