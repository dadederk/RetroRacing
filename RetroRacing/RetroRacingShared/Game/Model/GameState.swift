//
//  GameState.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// Mutable gameplay snapshot tracking progression, pause state, and scoring.
public struct GameState {
    public private(set) var level = 1
    public var isPaused = false
    public var lives = 3
    public var score = 0 {
        didSet {
            level = (score / 100) + 1
        }
    }
}
