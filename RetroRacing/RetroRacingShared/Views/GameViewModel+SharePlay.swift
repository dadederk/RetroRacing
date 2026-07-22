//
//  GameViewModel+SharePlay.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation

extension GameViewModel {
    /// True whenever a SharePlay match is in progress (any state other than idle).
    var isSharePlayActive: Bool {
        sharePlayState.isActive
    }

    /// Remote participant display name from GroupActivities, when available.
    var sharePlayOpponentDisplayName: String? {
        sharePlayOpponentName
    }

    /// Remaining lives reported for the opponent during an active round.
    var sharePlayRemoteLives: Int? {
        guard case .inRound(_, _, _, let remoteLives) = sharePlayState else { return nil }
        return remoteLives
    }

    /// Called by `GameView` whenever the app-level SharePlay state changes. `GameViewModel` is
    /// recreated every play session, so the composition root (`RetroRacingApp`) owns the
    /// long-lived `SharePlayMatchService` state-change handler and pushes each update down here,
    /// mirroring the existing `shouldStartGame` prop-down flow.
    func applySharePlayState(_ uiState: SharePlayUIState) {
        let previousState = sharePlayState
        sharePlayState = uiState.state
        sharePlayLocalRole = uiState.localRole
        sharePlayOpponentName = uiState.opponentDisplayName

        switch uiState.state {
        case .waitingForFriend:
            clearSharePlayResultSocialStats()
            pauseSharePlayGameplayLock()
        case .countdown(_, let difficulty):
            clearSharePlayResultSocialStats()
            if case .countdown = previousState {
                // Keep the existing scheduler state while the countdown ticks.
            } else {
                sharePlayCountdownCueScheduler.reset()
            }
            pauseSharePlayGameplayLock()
            applyGuestSpeedIfNeeded(sharedDifficulty: difficulty)
        case .inRound(let difficulty, _, _, _):
            releaseSharePlayGameplayLock()
            if case .countdown = previousState {
                updateDifficulty(difficulty)
                beginSharePlayRound()
            }
        case .waitingAfterLocalLoss(_, let localFinalScore):
            captureSharePlayResultSocialStatsIfNeeded(finalScore: localFinalScore)
            pauseSharePlayGameplayLock()
        case .retryWaiting,
             .retryTimedOut,
             .aborted:
            clearSharePlayResultSocialStats()
            pauseSharePlayGameplayLock()
            if case .retryTimedOut = uiState.state {
                restoreGuestSpeedIfNeeded()
            } else if case .aborted = uiState.state {
                restoreGuestSpeedIfNeeded()
            }
        case .finished(let result):
            captureSharePlayResultSocialStatsIfNeeded(
                finalScore: result.score(for: sharePlayLocalRole ?? .host)
            )
            pauseSharePlayGameplayLock()
            restoreGuestSpeedIfNeeded()
        case .idle:
            clearSharePlayResultSocialStats()
            releaseSharePlayGameplayLock()
            restoreGuestSpeedIfNeeded()
        }

        announceSharePlayStateChangeIfNeeded(from: previousState, to: uiState.state)
    }

    /// Reports the local player's live score and lives to the match service while a round is active.
    /// No-op when SharePlay isn't active, so regular solo gameplay is unaffected.
    func reportSharePlayScoreIfActive(score: Int, lives: Int) {
        guard case .inRound = sharePlayState, let sharePlayMatchService else { return }
        Task { await sharePlayMatchService.updateLocalScore(score, lives: lives) }
    }

    /// Reports the local player's elimination to the match service while a round is active.
    /// Called alongside (not instead of) the existing single-player game-over flow in
    /// `handleCollision()` — each player still submits their own score to the leaderboard.
    func reportSharePlayEliminationIfActive(finalScore: Int) {
        guard case .inRound = sharePlayState, let sharePlayMatchService else { return }
        Task {
            await sharePlayMatchService.reportLocalElimination(finalScore: finalScore)
        }
    }

    /// Plays the semantic countdown cue for a displayed countdown second. The scheduler keeps
    /// SwiftUI timeline refreshes from replaying the same second.
    func playSharePlayCountdownCue(for displayValue: Int) {
        guard let effect = sharePlayCountdownCueScheduler.cue(for: displayValue) else { return }
        scene?.play(effect)
    }

    /// Confirms local intent to play again after a finished SharePlay round.
    @discardableResult
    func retrySharePlayMatch() -> Bool {
        guard let sharePlayMatchService else { return false }
        Task { await sharePlayMatchService.retry() }
        return true
    }

    /// Leaves the current SharePlay session (user-initiated exit).
    func leaveSharePlayMatch() {
        guard let sharePlayMatchService else { return }
        restoreGuestSpeedIfNeeded()
        Task { await sharePlayMatchService.leaveSession() }
    }

    /// Applies the SharePlay start path when a view model is created after the round is already live.
    func startCurrentSharePlayRoundIfNeeded() {
        guard case .inRound(let difficulty, _, _, _) = sharePlayState else { return }
        applyGuestSpeedIfNeeded(sharedDifficulty: difficulty)
        beginSharePlayRound()
    }

    /// Resets the round and starts synchronized gameplay once the shared countdown elapses.
    /// Skips daily play-limit recording — SharePlay matches are always free (see
    /// `Requirements/monetization.md`, "SharePlay Exception").
    private func beginSharePlayRound() {
        clearSharePlayResultSocialStats()
        releaseSharePlayGameplayLock()
        scene?.play(.sharePlayCountdownGo)
        scene?.startImmediately()
        resetRunAchievementTelemetry()
        if let scene {
            let (currentScore, currentLives) = Self.scoreAndLives(from: scene)
            hud.score = currentScore
            hud.lives = currentLives
            reportSharePlayScoreIfActive(score: currentScore, lives: currentLives)
        }
        hud.showGameOver = false
        hud.gameOverScore = 0
        hud.gameOverBestScore = 0
        hud.gameOverDifficulty = selectedDifficulty
        hud.gameOverPreviousBestScore = nil
        hud.isNewHighScore = false
        hud.shouldRequestRatingOnGameOverModal = false
        hud.speedIncreaseImminent = false
    }

    private func pauseSharePlayGameplayLock() {
        scene?.pauseGameplay()
        scene?.setOverlayPauseLock(true)
    }

    private func releaseSharePlayGameplayLock() {
        scene?.setOverlayPauseLock(false)
    }

    private func applyGuestSpeedIfNeeded(sharedDifficulty: GameDifficulty) {
        guard sharePlayLocalRole == .guest else { return }
        sharePlayGuestSpeedRestore.captureIfNeeded(currentDifficulty: selectedDifficulty)
        updateDifficulty(sharedDifficulty)
    }

    private func restoreGuestSpeedIfNeeded() {
        guard let originalDifficulty = sharePlayGuestSpeedRestore.consumeRestoreValue() else { return }
        updateDifficulty(originalDifficulty)
    }

    private func announceSharePlayStateChangeIfNeeded(
        from previousState: SharePlayMatchState,
        to newState: SharePlayMatchState
    ) {
        guard previousState != newState else { return }
        let announcement: String?
        switch newState {
        case .waitingForFriend:
            announcement = GameLocalizedStrings.string("shareplay_announcement_waiting")
        case .countdown:
            announcement = GameLocalizedStrings.string("shareplay_announcement_countdown")
        case .inRound:
            guard case .countdown = previousState else { return }
            announcement = GameLocalizedStrings.string("shareplay_announcement_round_start")
        case .waitingAfterLocalLoss:
            announcement = GameLocalizedStrings.string("shareplay_announcement_waiting_for_opponent")
        case .finished(let result):
            let outcome = result.localOutcome(for: sharePlayLocalRole ?? .host)
            announcement = sharePlayFinishedAnnouncement(outcome: outcome, result: result)
        case .aborted(let reason):
            announcement = reason == .disconnected
                ? GameLocalizedStrings.string("shareplay_announcement_disconnected")
                : GameLocalizedStrings.string("shareplay_announcement_session_ended")
        default:
            announcement = nil
        }
        guard let announcement else { return }
        AccessibilityAnnouncementPoster().postAnnouncement(announcement, priority: .default)
    }

    private func sharePlayFinishedAnnouncement(
        outcome: SharePlayRoundResult.LocalOutcome,
        result: SharePlayRoundResult
    ) -> String {
        let localScore = result.score(for: sharePlayLocalRole ?? .host)
        let opponentScore = result.opponentScore(for: sharePlayLocalRole ?? .host)
        switch outcome {
        case .won:
            return GameLocalizedStrings.format("shareplay_announcement_won %lld %lld", localScore, opponentScore)
        case .lost:
            return GameLocalizedStrings.format("shareplay_announcement_lost %lld %lld", localScore, opponentScore)
        case .tie:
            return GameLocalizedStrings.format("shareplay_announcement_tie %lld %lld", localScore, opponentScore)
        }
    }
}

struct SharePlayCountdownCueScheduler: Sendable, Equatable {
    private var playedDisplayValues = Set<Int>()

    mutating func cue(for displayValue: Int) -> SoundEffect? {
        guard displayValue > 0 else { return nil }
        guard playedDisplayValues.insert(displayValue).inserted else { return nil }

        switch displayValue {
        case 1:
            return .sharePlayCountdownHigh
        case 2:
            return .sharePlayCountdownMid
        default:
            return .sharePlayCountdownLow
        }
    }

    mutating func reset() {
        playedDisplayValues.removeAll()
    }
}
