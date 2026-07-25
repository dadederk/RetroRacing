//
//  GameViewModel+ScreenshotCapture.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 23/07/2026.
//

import SpriteKit

extension GameViewModel {
    func applyScreenshotLayout(_ layout: GameScreenshotLayout, to scene: GameScene) {
        isScreenshotCapturePinned = true
        scene.applyScreenshotLayout(layout)
        updateBigRivalCarsEnabled(ScreenshotCapturePreferences.gameplayBigCarsEnabled)
        updateRoadVisualStyle(ScreenshotCapturePreferences.gameplayRoadVisualStyle)
        currentUpcomingFriendMilestone = layout.upcomingMilestones.first
        hud.score = layout.score
        hud.lives = layout.lives
        hud.speedIncreaseImminent = layout.speedIncreaseImminent
        hud.showGameOver = false
    }
}
