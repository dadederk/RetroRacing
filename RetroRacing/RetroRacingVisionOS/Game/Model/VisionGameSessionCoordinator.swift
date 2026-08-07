//
//  VisionGameSessionCoordinator.swift
//  RetroRacingVisionOS
//
//  Created by Dani Devesa on 05/08/2026.
//

import Foundation
import Observation
import RetroRacingShared

/// Owns one gameplay engine while SwiftUI moves the presentation into spatial mode.
@MainActor
@Observable
final class VisionGameSessionCoordinator: RacingGameController {
    private(set) var snapshot: GameSnapshot
    private(set) var screen: VisionGameScreen = .menu
    private(set) var presentation: VisionGamePresentation = .classic
    private(set) var spatialState: VisionSpatialState = .inactive
    private(set) var focusRestorationSequence = 0
    private(set) var sharePlayUIState: SharePlayUIState = .idle
    private(set) var requiresClassicForSharePlay = false
    private(set) var isSharePlayActivationFailurePresented = false
    private(set) var gameOverScoreSummary: GameOverScoreSummary?

    @ObservationIgnored private let engine: any GameEngineProtocol
    @ObservationIgnored private let scheduler: any GameLoopScheduling
    @ObservationIgnored private let spatialPresentationCoordinator: VisionSpatialPresentationCoordinator
    @ObservationIgnored let tabletopModelRepository: any TabletopModelRepositoryProtocol
    @ObservationIgnored private let controllerInputSource: any GameControllerInputSource
    @ObservationIgnored private let difficultyProvider: @MainActor () -> GameDifficulty
    @ObservationIgnored private let sharePlayMatchService: any SharePlayMatchService
    @ObservationIgnored private let audioFeedbackCoordinator: GameplayAudioFeedbackCoordinator
    @ObservationIgnored private let leaderboardService: any LeaderboardService
    @ObservationIgnored private let highestScoreStore: any HighestScoreStore
    @ObservationIgnored private let announcementPoster: any AccessibilityAnnouncementPosting
    @ObservationIgnored private var nextSpatialTransitionID: UInt64 = 0
    @ObservationIgnored private var activeSpatialTransitionID: VisionSpatialTransitionID?
    @ObservationIgnored private var activePresentations = Set<VisionGamePresentation>()
    @ObservationIgnored private var appliedSharePlayState: SharePlayMatchState = .idle
    @ObservationIgnored private var didSubmitCurrentRun = false

    init(
        engine: any GameEngineProtocol,
        scheduler: any GameLoopScheduling,
        spatialPresentationCoordinator: VisionSpatialPresentationCoordinator,
        tabletopModelRepository: any TabletopModelRepositoryProtocol,
        controllerInputSource: any GameControllerInputSource,
        difficultyProvider: @escaping @MainActor () -> GameDifficulty,
        sharePlayMatchService: any SharePlayMatchService,
        audioFeedbackCoordinator: GameplayAudioFeedbackCoordinator,
        leaderboardService: any LeaderboardService,
        highestScoreStore: any HighestScoreStore,
        announcementPoster: any AccessibilityAnnouncementPosting
    ) {
        self.engine = engine
        self.scheduler = scheduler
        self.spatialPresentationCoordinator = spatialPresentationCoordinator
        self.tabletopModelRepository = tabletopModelRepository
        self.controllerInputSource = controllerInputSource
        self.difficultyProvider = difficultyProvider
        self.sharePlayMatchService = sharePlayMatchService
        self.audioFeedbackCoordinator = audioFeedbackCoordinator
        self.leaderboardService = leaderboardService
        self.highestScoreStore = highestScoreStore
        self.announcementPoster = announcementPoster
        self.snapshot = engine.snapshot
    }

    var isPlaying: Bool { screen == .playing || screen == .gameOver }
    var isUserPaused: Bool { snapshot.activePauseReasons.contains(.user) }
    var spatialFailure: VisionSpatialFailure? {
        guard case .failure(let failure) = spatialState else { return nil }
        return failure
    }
    var canEnterSpatialMode: Bool {
        isPlaying
            && presentation == .classic
            && isSharePlayActive == false
            && (spatialState == .inactive || spatialFailure != nil)
    }
    var isSpatialLaneInputEnabled: Bool {
        spatialState == .active && screen == .playing && snapshot.phase == .running
    }
    var isSharePlayActive: Bool { sharePlayUIState.state.isActive }
    var sharePlayRemoteScore: Int? {
        guard case .inRound(_, _, let remoteScore, _) = sharePlayUIState.state else { return nil }
        return remoteScore
    }
    var sharePlayRemoteLives: Int? {
        guard case .inRound(_, _, _, let remoteLives) = sharePlayUIState.state else { return nil }
        return remoteLives
    }
    var shouldPresentSharePlayResult: Bool {
        switch sharePlayUIState.state {
        case .finished, .retryWaiting, .retryTimedOut, .aborted:
            return true
        case .idle, .waitingForFriend, .countdown, .inRound, .waitingAfterLocalLoss:
            return false
        @unknown default:
            return false
        }
    }

    func play() {
        spatialPresentationCoordinator.cancel()
        activeSpatialTransitionID = nil
        spatialState = .inactive
        screen = .playing
        startSoloRun(command: .start)
    }

    func restart() {
        if isSharePlayActive {
            retrySharePlay()
            return
        }
        screen = .playing
        startSoloRun(command: .restart)
    }

    func finish() {
        if isSharePlayActive {
            Task { @concurrent [sharePlayMatchService] in
                await sharePlayMatchService.leaveSession()
            }
        }
        spatialPresentationCoordinator.cancel()
        activeSpatialTransitionID = nil
        scheduler.stop()
        audioFeedbackCoordinator.stopAll()
        apply(.finish)
        screen = .menu
        presentation = .classic
        spatialState = .inactive
        requiresClassicForSharePlay = false
        gameOverScoreSummary = nil
    }

    func moveLeft() {
        guard screen == .playing else { return }
        apply(.move(.left))
    }

    func moveRight() {
        guard screen == .playing else { return }
        apply(.move(.right))
    }

    func selectLane(_ lane: Int) {
        guard screen == .playing else { return }
        guard let direction = GameLaneSelectionResolver.direction(
            selectedLane: lane,
            currentLane: snapshot.playerColumn,
            laneCount: snapshot.numberOfColumns
        ) else { return }
        apply(.move(direction))
    }

    func togglePause() {
        guard screen == .playing else { return }
        if isSharePlayActive {
            guard case .inRound = sharePlayUIState.state else { return }
        }
        if isUserPaused {
            resumeWithStartCue()
        } else {
            apply(.setPause(reason: .user, isActive: true))
        }
    }

    func setOverlayPresented(_ isPresented: Bool) {
        guard screen == .playing else { return }
        apply(.setPause(reason: .overlay, isActive: isPresented))
    }

    @discardableResult
    func beginSpatialPresentation(using actions: VisionSpatialActions) -> Bool {
        guard canEnterSpatialMode else { return false }

        nextSpatialTransitionID &+= 1
        let transitionID = VisionSpatialTransitionID(rawValue: nextSpatialTransitionID)
        activeSpatialTransitionID = transitionID
        spatialState = .preflighting
        apply(.setPause(reason: .presentationTransition, isActive: true))
        apply(.setPause(reason: .spatialReady, isActive: true))
        spatialPresentationCoordinator.begin(
            transitionID: transitionID,
            using: actions,
            onOpening: { [weak self] transitionID in
                self?.spatialPreflightDidComplete(transitionID: transitionID)
            },
            onFailure: { [weak self] transitionID, failure, error in
                self?.recoverSpatialPresentation(
                    transitionID: transitionID,
                    failure: failure,
                    underlyingError: error
                )
            }
        )
        return true
    }

    func spatialContentDidBecomeReady(
        transitionID: VisionSpatialTransitionID,
        using actions: VisionSpatialActions
    ) {
        guard activeSpatialTransitionID == transitionID,
              spatialState == .opening else {
            return
        }
        spatialState = .ready
        presentation = .spatial
        apply(.setPause(reason: .presentationTransition, isActive: false))
        focusRestorationSequence &+= 1
        spatialPresentationCoordinator.hideClassic(using: actions)
        refreshScheduler()
    }

    func spatialContentDidFail(
        transitionID: VisionSpatialTransitionID,
        underlyingError: Error,
        using actions: VisionSpatialActions
    ) {
        guard activeSpatialTransitionID == transitionID else { return }
        recoverSpatialPresentation(
            transitionID: transitionID,
            failure: .modelUnavailable,
            underlyingError: underlyingError
        )
        spatialPresentationCoordinator.dismissVolume(using: actions)
    }

    func startSpatialGame() {
        guard spatialState == .ready else { return }
        spatialState = .active
        focusRestorationSequence &+= 1
        resumeSpatialGameWithStartCue()
    }

    func finishSpatialPresentation(using actions: VisionSpatialActions) {
        finish()
        spatialPresentationCoordinator.restoreClassicAndDismissVolume(using: actions)
    }

    func cancelSpatialPresentation(using actions: VisionSpatialActions) {
        guard spatialState != .inactive else { return }
        let shouldDismissVolume = spatialState.isSpatialContentPresented
        presentation = .classic
        activeSpatialTransitionID = nil
        spatialState = .inactive
        apply(.setPause(reason: .presentationTransition, isActive: false))
        apply(.setPause(reason: .spatialReady, isActive: false))
        focusRestorationSequence &+= 1
        if shouldDismissVolume {
            spatialPresentationCoordinator.dismissVolume(using: actions)
        } else {
            spatialPresentationCoordinator.cancel()
        }
        refreshScheduler()
        if requiresClassicForSharePlay {
            completeSharePlayClassicHandoff()
        }
    }

    @discardableResult
    func beginReturnToClassic(using actions: VisionSpatialActions) -> Bool {
        guard spatialState.isSpatialContentPresented,
              spatialState != .returning else {
            return false
        }
        let shouldRestoreClassic = presentation == .spatial
        spatialState = .returning
        apply(.setPause(reason: .presentationTransition, isActive: true))
        apply(.setPause(reason: .spatialReady, isActive: true))
        if shouldRestoreClassic {
            spatialPresentationCoordinator.restoreClassicAndDismissVolume(using: actions)
        } else {
            spatialPresentationCoordinator.dismissVolume(using: actions)
        }
        return true
    }

    func classicDidBecomeReady() {
        guard spatialState == .returning else { return }
        presentation = .classic
        activeSpatialTransitionID = nil
        spatialState = .inactive
        apply(.setPause(reason: .presentationTransition, isActive: false))
        apply(.setPause(reason: .spatialReady, isActive: false))
        focusRestorationSequence &+= 1
        spatialPresentationCoordinator.cancel()
        refreshScheduler()
        if requiresClassicForSharePlay {
            completeSharePlayClassicHandoff()
        }
    }

    func spatialSceneDidDisappear(using actions: VisionSpatialActions) {
        switch spatialState {
        case .opening, .ready, .active:
            let shouldRestoreClassic = presentation == .spatial
            spatialPresentationCoordinator.cancel()
            activeSpatialTransitionID = nil
            presentation = .classic
            spatialState = .inactive
            apply(.setPause(reason: .presentationTransition, isActive: false))
            apply(.setPause(reason: .spatialReady, isActive: false))
            focusRestorationSequence &+= 1
            if shouldRestoreClassic {
                spatialPresentationCoordinator.restoreClassic(using: actions)
            }
            refreshScheduler()
            if requiresClassicForSharePlay {
                completeSharePlayClassicHandoff()
            }
        case .inactive, .preflighting, .returning, .failure:
            break
        }
    }

    func spatialDidEnterBackground(using actions: VisionSpatialActions) {
        guard spatialState.isSpatialContentPresented else { return }
        _ = beginReturnToClassic(using: actions)
    }

    func currentSpatialTransitionID() -> VisionSpatialTransitionID? {
        activeSpatialTransitionID
    }

    func setPresentationActive(_ presentation: VisionGamePresentation, isActive: Bool) {
        let hadActivePresentation = activePresentations.isEmpty == false
        if isActive {
            activePresentations.insert(presentation)
        } else {
            activePresentations.remove(presentation)
        }
        let hasActivePresentation = activePresentations.isEmpty == false
        if hadActivePresentation == false, hasActivePresentation {
            controllerInputSource.start { [weak self] action in
                self?.handleControllerAction(action)
            }
        } else if hadActivePresentation, hasActivePresentation == false {
            controllerInputSource.stop()
        }
        apply(.setPause(reason: .appInactive, isActive: activePresentations.isEmpty))
        refreshScheduler()
    }

    func clearSpatialFailure() {
        guard spatialFailure != nil else { return }
        spatialState = .inactive
    }

    func clearSharePlayActivationFailure() {
        isSharePlayActivationFailurePresented = false
    }

    func requestSharePlay() {
        guard isSharePlayActive == false else { return }
        isSharePlayActivationFailurePresented = false
        Task { @concurrent [sharePlayMatchService] in
            guard await sharePlayMatchService.prepareHostActivation() else { return }
            let didActivate = await sharePlayMatchService.activatePendingHostSession(
                reason: .eligibleMenuRequest
            )
            guard didActivate == false else { return }
            await MainActor.run { [weak self] in
                self?.isSharePlayActivationFailurePresented = true
            }
        }
    }

    func observeSharePlaySessions() async {
        await sharePlayMatchService.setStateChangeHandler { [weak self] uiState in
            await self?.applySharePlayState(uiState)
        }
        await sharePlayMatchService.observeIncomingSessions()
    }

    func retrySharePlay() {
        guard isSharePlayActive else { return }
        Task { @concurrent [sharePlayMatchService] in
            await sharePlayMatchService.retry()
        }
    }

    func leaveSharePlay() {
        finish()
    }

    func playSharePlayCountdownCue(displayValue: Int) {
        audioFeedbackCoordinator.playSharePlayCountdown(displayValue: displayValue)
    }

    private func tick(elapsedTime: TimeInterval) {
        guard screen == .playing, activePresentations.isEmpty == false else { return }
        apply(.tick(elapsedTime: elapsedTime))
    }

    private func handleControllerAction(_ action: GameControllerAction) {
        switch action {
        case .moveLeft: moveLeft()
        case .moveRight: moveRight()
        case .pauseResume: togglePause()
        @unknown default: break
        }
    }

    private func apply(_ command: GameCommand) {
        let previousSnapshot = snapshot
        let events = engine.handle(command)
        let newSnapshot = engine.snapshot
        if snapshot != newSnapshot {
            snapshot = newSnapshot
        }
        audioFeedbackCoordinator.process(
            previousSnapshot: previousSnapshot,
            snapshot: newSnapshot,
            events: events
        )
        process(events)
    }

    private func process(_ events: [GameEvent]) {
        for event in events {
            switch event {
            case .scoreChanged(let score):
                reportSharePlayScoreIfNeeded(score: score, lives: snapshot.lives)
            case .collision:
                scheduler.stop()
                audioFeedbackCoordinator.playCollision { [weak self] in
                    self?.resolveCollisionAfterFeedback()
                }
            case .collisionResolved:
                reportSharePlayScoreIfNeeded(score: snapshot.score, lives: snapshot.lives)
                refreshScheduler()
            case .gameOver(let score):
                handleGameOver(score: score)
            case .started, .laneChanged, .levelChangeImminent, .pauseChanged,
                 .restarted, .finished:
                break
            @unknown default:
                break
            }
        }
    }

    private func spatialPreflightDidComplete(transitionID: VisionSpatialTransitionID) {
        guard activeSpatialTransitionID == transitionID,
              spatialState == .preflighting else {
            return
        }
        spatialState = .opening
    }

    private func recoverSpatialPresentation(
        transitionID: VisionSpatialTransitionID?,
        failure: VisionSpatialFailure,
        underlyingError: Error?
    ) {
        if let transitionID, activeSpatialTransitionID != transitionID { return }
        let failedTransitionID = activeSpatialTransitionID
        spatialPresentationCoordinator.cancel()
        activeSpatialTransitionID = nil
        presentation = .classic
        spatialState = .failure(failure)
        apply(.setPause(reason: .presentationTransition, isActive: false))
        apply(.setPause(reason: .spatialReady, isActive: false))
        focusRestorationSequence &+= 1
        logSpatialFailure(
            failure,
            transitionID: failedTransitionID,
            underlyingError: underlyingError
        )
        refreshScheduler()
        if requiresClassicForSharePlay {
            completeSharePlayClassicHandoff()
        }
    }

    private func logSpatialFailure(
        _ failure: VisionSpatialFailure,
        transitionID: VisionSpatialTransitionID?,
        underlyingError: Error?
    ) {
        var fields: [AppLog.Field] = [
            .reason(failure.rawValue),
            .string("source", "classic"),
            .string("destination", "spatial")
        ]
        if let transitionID {
            fields.append(.int64("transitionID", Int64(transitionID.rawValue)))
        }
        if let underlyingError {
            fields.append(contentsOf: AppLog.Field.error(underlyingError))
        }
        AppLog.error(
            AppLog.game + AppLog.lifecycle,
            "VISION_SPATIAL_PRESENTATION",
            outcome: .failed,
            fields: fields
        )
    }

    private func refreshScheduler() {
        guard screen == .playing,
              activePresentations.isEmpty == false,
              snapshot.phase != .collision,
              snapshot.phase != .gameOver,
              snapshot.phase != .finished else {
            scheduler.stop()
            return
        }
        scheduler.start { [weak self] elapsedTime in
            self?.tick(elapsedTime: elapsedTime)
        }
    }

    private func startSoloRun(command: GameCommand) {
        didSubmitCurrentRun = false
        gameOverScoreSummary = nil
        audioFeedbackCoordinator.refreshVolume()
        apply(.setDifficulty(difficultyProvider()))
        apply(command)
        apply(.setPause(reason: .startup, isActive: true))
        refreshScheduler()
        audioFeedbackCoordinator.playStart { [weak self] in
            guard let self, self.isSharePlayActive == false else { return }
            self.apply(.setPause(reason: .startup, isActive: false))
            self.refreshScheduler()
        }
    }

    private func resumeWithStartCue() {
        audioFeedbackCoordinator.refreshVolume()
        apply(.setPause(reason: .startup, isActive: true))
        apply(.setPause(reason: .user, isActive: false))
        audioFeedbackCoordinator.playStart { [weak self] in
            guard let self else { return }
            self.apply(.setPause(reason: .startup, isActive: false))
            self.refreshScheduler()
        }
    }

    private func resumeSpatialGameWithStartCue() {
        audioFeedbackCoordinator.refreshVolume()
        apply(.setPause(reason: .startup, isActive: true))
        apply(.setPause(reason: .spatialReady, isActive: false))
        apply(.setPause(reason: .user, isActive: false))
        audioFeedbackCoordinator.playStart { [weak self] in
            guard let self else { return }
            self.apply(.setPause(reason: .startup, isActive: false))
            self.refreshScheduler()
        }
    }

    private func resolveCollisionAfterFeedback() {
        guard snapshot.phase == .collision else { return }
        apply(.resolveCollision)
        refreshScheduler()
    }

    private func handleGameOver(score: Int) {
        scheduler.stop()
        guard didSubmitCurrentRun == false else { return }
        didSubmitCurrentRun = true
        if case .inRound = appliedSharePlayState {
            let difficulty = snapshot.difficulty
            leaderboardService.submitScore(score, difficulty: difficulty)
            gameOverScoreSummary = highestScoreStore.evaluateGameOverScore(
                score,
                difficulty: difficulty
            )
            Task { @concurrent [sharePlayMatchService] in
                await sharePlayMatchService.reportLocalElimination(finalScore: score)
            }
            return
        }
        screen = .gameOver
    }

    private func reportSharePlayScoreIfNeeded(score: Int, lives: Int) {
        guard case .inRound = appliedSharePlayState else { return }
        Task { @concurrent [sharePlayMatchService] in
            await sharePlayMatchService.updateLocalScore(score, lives: lives)
        }
    }

    func applySharePlayState(_ uiState: SharePlayUIState) {
        let previousState = sharePlayUIState.state
        sharePlayUIState = uiState

        if uiState.state.isActive,
           presentation != .classic || spatialState.isSpatialContentPresented {
            requiresClassicForSharePlay = true
            apply(.setPause(reason: .sharePlay, isActive: true))
            announceSharePlayStateChangeIfNeeded(from: previousState, to: uiState.state)
            return
        }

        requiresClassicForSharePlay = false
        applySharePlayStateInClassic(uiState)
        announceSharePlayStateChangeIfNeeded(from: previousState, to: uiState.state)
    }

    private func applySharePlayStateInClassic(_ uiState: SharePlayUIState) {
        let previousAppliedState = appliedSharePlayState
        appliedSharePlayState = uiState.state

        switch uiState.state {
        case .waitingForFriend:
            prepareSharePlayWaitingState()
        case .countdown(_, let settings):
            prepareSharePlayWaitingState()
            apply(.setDifficulty(settings.difficulty))
            apply(.setTrafficMode(.seeded(settings.trafficSeed)))
            if case .countdown = previousAppliedState {
                // Preserve the countdown cue de-duplication state across timer refreshes.
            } else {
                audioFeedbackCoordinator.resetSharePlayCountdown()
            }
        case .inRound(let settings, _, _, _):
            if case .inRound = previousAppliedState {
                break
            }
            beginSharePlayRound(settings: settings)
        case .waitingAfterLocalLoss:
            screen = .playing
            apply(.setPause(reason: .sharePlay, isActive: true))
            scheduler.stop()
        case .finished(let result):
            screen = .playing
            apply(.setPause(reason: .sharePlay, isActive: true))
            scheduler.stop()
            ensureSharePlayScoreSummary(result: result, role: uiState.localRole)
        case .retryWaiting, .retryTimedOut, .aborted:
            screen = .playing
            apply(.setPause(reason: .sharePlay, isActive: true))
            scheduler.stop()
        case .idle:
            apply(.setPause(reason: .sharePlay, isActive: false))
            audioFeedbackCoordinator.resetSharePlayCountdown()
        @unknown default:
            screen = .playing
            apply(.setPause(reason: .sharePlay, isActive: true))
            scheduler.stop()
        }
    }

    private func prepareSharePlayWaitingState() {
        screen = .playing
        apply(.setPause(reason: .sharePlay, isActive: true))
        scheduler.stop()
        gameOverScoreSummary = nil
    }

    private func beginSharePlayRound(settings: SharePlayRoundSettings) {
        screen = .playing
        didSubmitCurrentRun = false
        gameOverScoreSummary = nil
        audioFeedbackCoordinator.refreshVolume()
        apply(.setDifficulty(settings.difficulty))
        apply(.setTrafficMode(.seeded(settings.trafficSeed)))
        apply(.start)
        apply(.setPause(reason: .sharePlay, isActive: false))
        audioFeedbackCoordinator.playSharePlayGo()
        reportSharePlayScoreIfNeeded(score: snapshot.score, lives: snapshot.lives)
        refreshScheduler()
    }

    private func ensureSharePlayScoreSummary(
        result: SharePlayRoundResult,
        role: SharePlayPlayerRole?
    ) {
        guard gameOverScoreSummary == nil else { return }
        let score = result.score(for: role ?? .host)
        gameOverScoreSummary = highestScoreStore.evaluateGameOverScore(
            score,
            difficulty: result.difficulty
        )
    }

    private func completeSharePlayClassicHandoff() {
        requiresClassicForSharePlay = false
        applySharePlayStateInClassic(sharePlayUIState)
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
            announcement = sharePlayFinishedAnnouncement(result: result)
        case .aborted(let reason):
            announcement = reason == .disconnected
                ? GameLocalizedStrings.string("shareplay_announcement_disconnected")
                : GameLocalizedStrings.string("shareplay_announcement_session_ended")
        case .idle, .retryWaiting, .retryTimedOut:
            announcement = nil
        @unknown default:
            announcement = nil
        }
        guard let announcement else { return }
        announcementPoster.postAnnouncement(announcement, priority: .default)
    }

    private func sharePlayFinishedAnnouncement(result: SharePlayRoundResult) -> String {
        let role = sharePlayUIState.localRole ?? .host
        let localScore = result.score(for: role)
        let opponentScore = result.opponentScore(for: role)
        switch result.localOutcome(for: role) {
        case .won:
            return GameLocalizedStrings.format(
                "shareplay_announcement_won %lld %lld",
                localScore,
                opponentScore
            )
        case .lost:
            return GameLocalizedStrings.format(
                "shareplay_announcement_lost %lld %lld",
                localScore,
                opponentScore
            )
        case .tie:
            return GameLocalizedStrings.format(
                "shareplay_announcement_tie %lld %lld",
                localScore,
                opponentScore
            )
        @unknown default:
            return GameLocalizedStrings.string("shareplay_announcement_session_ended")
        }
    }
}
