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
        hud.gameOverScore = 0
        hud.gameOverBestScore = 0
        hud.gameOverDifficulty = selectedDifficulty
        hud.gameOverPreviousBestScore = nil
        hud.isNewHighScore = false
        hud.shouldRequestRatingOnGameOverModal = false
        hud.speedIncreaseImminent = false

        // Record this restart against the daily play limit, if enabled.
        // This ensures each "round" (start or restart) counts toward the limit.
        playLimitService?.recordGamePlayed(on: Date())
    }

    func handleCollision() {
        guard let scene else { return }
        let (currentScore, currentLives) = Self.scoreAndLives(from: scene)
        hud.lives = currentLives
        if currentLives == 0 {
            let difficultyAtGameOver = selectedDifficulty
            leaderboardService.submitScore(currentScore, difficulty: difficultyAtGameOver)
            let scoreSummary = highestScoreStore.evaluateGameOverScore(
                currentScore,
                difficulty: difficultyAtGameOver
            )
            hud.isNewHighScore = scoreSummary.isNewRecord
            hud.gameOverScore = scoreSummary.score
            hud.gameOverBestScore = scoreSummary.bestScore
            hud.gameOverDifficulty = difficultyAtGameOver
            hud.gameOverPreviousBestScore = scoreSummary.previousBestScore
            hud.shouldRequestRatingOnGameOverModal = scoreSummary.isNewRecord
            if scoreSummary.isNewRecord {
                hapticController?.triggerSuccessHaptic()
            }
            hud.showGameOver = true
        } else {
            scene.resume()
        }
    }

    /// Triggers the rating check exactly once when the game-over modal is presented.
    func handleGameOverModalPresentedIfNeeded() {
        guard hud.shouldRequestRatingOnGameOverModal else { return }
        hud.shouldRequestRatingOnGameOverModal = false
        ratingService.recordBestScoreImprovementAndRequestIfEligible()
    }

    /// Dismisses game-over presentation and clears one-shot modal state.
    func dismissGameOverModal() {
        hud.showGameOver = false
        hud.shouldRequestRatingOnGameOverModal = false
    }

    /// Pauses or resumes gameplay when the menu overlay is presented or dismissed.
    /// If the user has explicitly paused the game, overlay dismissal will not resume it.
    func setOverlayPause(isPresented: Bool) {
        isMenuOverlayPresented = isPresented
        guard let scene else { return }
        scene.setOverlayPauseLock(isPresented)
        if isPresented {
            scene.pauseGameplay()
        } else if pause.isUserPaused == false {
            scene.unpauseGameplay()
        }
    }
}
