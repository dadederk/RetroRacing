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
        resetRunAchievementTelemetry()
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
        hud.gameOverNextFriendAhead = nil
        hud.gameOverOvertakenFriends = []
        hud.gameOverNewlyAchievedAchievementIDs = []
        hud.isNewHighScore = false
        hud.shouldRequestRatingOnGameOverModal = false
        hud.speedIncreaseImminent = false
        overtakenFriendPlayerIDs.removeAll()
        currentUpcomingFriendMilestone = nil
        pendingFriendOvertakeAnnouncement = nil
        scene?.setUpcomingFriendMilestones([])

        // Record this restart against the daily play limit, if enabled.
        // This ensures each "round" (start or restart) counts toward the limit.
        playLimitService?.recordGamePlayed(on: Date())

        Task { [weak self] in
            guard let self else { return }
            await refreshFriendMilestonesForCurrentRun()
        }
    }

    func handleCollision() {
        guard let scene else { return }
        let (currentScore, currentLives) = Self.scoreAndLives(from: scene)
        hud.lives = currentLives
        if currentLives == 0 {
            recordVoiceOverControlIfNeeded()
            let difficultyAtGameOver = selectedDifficulty
            leaderboardService.submitScore(currentScore, difficulty: difficultyAtGameOver)
            let achievementUpdate = achievementProgressService.recordCompletedRun(
                CompletedRunAchievementData(
                    overtakes: currentScore,
                    usedControls: runInputTelemetry.usedInputs,
                    completedAt: Date(),
                    activeAssistiveTechnologies: runInputTelemetry.usedAssistiveTechnologies
                )
            )
            var newlyAchievedAchievementIDs = achievementUpdate.newlyAchievedAchievementIDs
                .sorted { $0.rawValue < $1.rawValue }
            if let debugForcedAchievementIdentifier,
               newlyAchievedAchievementIDs.contains(debugForcedAchievementIdentifier) == false {
                newlyAchievedAchievementIDs.append(debugForcedAchievementIdentifier)
                newlyAchievedAchievementIDs.sort { $0.rawValue < $1.rawValue }
            }
            hud.gameOverNewlyAchievedAchievementIDs = newlyAchievedAchievementIDs
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
            applyFriendGameOverSummaries(finalScore: currentScore)
            hud.showGameOver = true
        } else {
            scene.resume()
        }
    }

    func setDebugForcedAchievementIdentifier(_ achievementIdentifier: AchievementIdentifier?) {
        guard BuildConfiguration.shouldShowDebugFeatures else {
            debugForcedAchievementIdentifier = nil
            return
        }
        debugForcedAchievementIdentifier = achievementIdentifier
    }

    func recordControlInput(_ input: AchievementControlInput) {
        runInputTelemetry.record(input)
        recordActiveAssistiveTechnologiesIfNeeded()
    }

    func recordVoiceOverControlIfNeeded() {
        recordActiveAssistiveTechnologiesIfNeeded()
    }

    func resetRunAchievementTelemetry() {
        runInputTelemetry.reset()
        recordActiveAssistiveTechnologiesIfNeeded()
    }

    private func recordActiveAssistiveTechnologiesIfNeeded() {
        let activeTechnologies = AssistiveTechnologyStatus.activeTechnologies
        for technology in activeTechnologies {
            runInputTelemetry.recordAssistiveTechnology(technology)
        }
        if activeTechnologies.contains(.voiceOver) {
            runInputTelemetry.record(.voiceOver)
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
        hud.gameOverNextFriendAhead = nil
        hud.gameOverOvertakenFriends = []
        hud.gameOverNewlyAchievedAchievementIDs = []
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
