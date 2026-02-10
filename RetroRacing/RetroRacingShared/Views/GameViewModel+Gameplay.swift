//
//  GameViewModel+Gameplay.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 2026-02-05.
//

import Foundation

extension GameViewModel {
    func restartGame() {
        scene?.start()
        if let scene {
            let (currentScore, currentLives) = Self.scoreAndLives(from: scene)
            hud.score = currentScore
            hud.lives = currentLives
        }
        hud.showGameOver = false
        hud.isNewHighScore = false
    }

    func handleCollision() {
        guard let scene else { return }
        let (currentScore, currentLives) = Self.scoreAndLives(from: scene)
        hud.lives = currentLives
        if currentLives == 0 {
            leaderboardService.submitScore(currentScore)
            ratingService.checkAndRequestRating(score: currentScore)
            hud.isNewHighScore = highestScoreStore.updateIfHigher(currentScore)
            if hud.isNewHighScore {
                hapticController?.triggerSuccessHaptic()
            }
            hud.gameOverScore = currentScore
            hud.showGameOver = true
        } else {
            scene.resume()
        }
    }

    /// Pauses or resumes gameplay when the menu overlay is presented or dismissed.
    /// If the user has explicitly paused the game, overlay dismissal will not resume it.
    func setOverlayPause(isPresented: Bool) {
        isMenuOverlayPresented = isPresented
        guard let scene else { return }
        if isPresented {
            scene.pauseGameplay()
        } else if pause.isUserPaused == false {
            scene.unpauseGameplay()
        }
    }
}
