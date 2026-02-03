//
//  GameSceneDelegate.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// Delegate interface used to surface GameScene events to platform-specific UIs.
public protocol GameSceneDelegate: AnyObject {
    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int)
    func gameSceneDidDetectCollision(_ gameScene: GameScene)
    /// Called once per timer-driven grid advance (new row), not on move left/right.
    func gameSceneDidUpdateGrid(_ gameScene: GameScene)
    /// Called whenever the pause state changes (user pause, crash pause, resume).
    func gameScene(_ gameScene: GameScene, didUpdatePauseState isPaused: Bool)
    /// Called when a new personal best is achieved so the UI layer can react (e.g. haptic and messaging).
    func gameScene(_ gameScene: GameScene, didAchieveNewHighScore score: Int)
}

public extension GameSceneDelegate {
    func gameScene(_ gameScene: GameScene, didUpdatePauseState isPaused: Bool) { }
    func gameScene(_ gameScene: GameScene, didAchieveNewHighScore score: Int) { }
}
