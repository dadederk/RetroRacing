//
//  GameViewModelTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 11/02/2026.
//

import XCTest
import SpriteKit
@testable import RetroRacingShared

/// Tests for GameViewModel pause state management, particularly menu overlay behavior.
@MainActor
final class GameViewModelTests: XCTestCase {
    private var leaderboardService: MockLeaderboardService!
    private var ratingService: MockRatingService!
    private var highestScoreStore: MockHighestScoreStore!
    private var achievementProgressService: MockAchievementProgressService!
    private var inputAdapterFactory: MockInputAdapterFactory!
    private var viewModel: GameViewModel!
    
    override func setUp() {
        super.setUp()
        leaderboardService = MockLeaderboardService()
        ratingService = MockRatingService()
        highestScoreStore = MockHighestScoreStore()
        achievementProgressService = MockAchievementProgressService()
        inputAdapterFactory = MockInputAdapterFactory()
        viewModel = GameViewModel(
            leaderboardService: leaderboardService,
            ratingService: ratingService,
            theme: nil,
            hapticController: nil,
            highestScoreStore: highestScoreStore,
            achievementProgressService: achievementProgressService,
            inputAdapterFactory: inputAdapterFactory,
            playLimitService: nil,
            specialEventService: nil,
            selectedDifficulty: .rapid,
            selectedAudioFeedbackMode: .retro,
            selectedLaneMoveCueStyle: .laneConfirmationAndSafety,
            selectedBigRivalCarsEnabled: false,
            selectedRoadVisualStyle: .detailedRoad,
            shouldStartGame: true
        )
    }
    
    override func tearDown() {
        viewModel = nil
        inputAdapterFactory = nil
        highestScoreStore = nil
        achievementProgressService = nil
        ratingService = nil
        leaderboardService = nil
        super.tearDown()
    }
    
    func testGivenMenuOverlayNotPresentedWhenSettingOverlayPauseThenGameIsPaused() {
        // Given
        let imageLoader = MockImageLoader()
        let soundPlayer = MockSoundPlayer()
        let laneCuePlayer = MockLaneCuePlayerStub()
        let scene = GameScene(
            size: CGSize(width: 100, height: 100),
            theme: nil,
            imageLoader: imageLoader,
            soundPlayer: soundPlayer,
            laneCuePlayer: laneCuePlayer,
            hapticController: nil,
            audioFeedbackMode: .retro,
            laneMoveCueStyle: .laneConfirmationAndSafety,
            difficulty: .rapid
        )
        // Unpause the scene so we can test overlay pause behavior
        scene.unpauseGameplay()
        viewModel.scene = scene
        
        // When
        viewModel.setOverlayPause(isPresented: true)
        
        // Then
        XCTAssertTrue(scene.gameState.isPaused, "Game should be paused when menu overlay is presented")
    }
    
    func testGivenMenuOverlayPresentedWhenDismissingOverlayThenGameResumes() {
        // Given
        let imageLoader = MockImageLoader()
        let soundPlayer = MockSoundPlayer()
        let laneCuePlayer = MockLaneCuePlayerStub()
        let scene = GameScene(
            size: CGSize(width: 100, height: 100),
            theme: nil,
            imageLoader: imageLoader,
            soundPlayer: soundPlayer,
            laneCuePlayer: laneCuePlayer,
            hapticController: nil,
            audioFeedbackMode: .retro,
            laneMoveCueStyle: .laneConfirmationAndSafety,
            difficulty: .rapid
        )
        scene.unpauseGameplay()
        viewModel.scene = scene
        viewModel.setOverlayPause(isPresented: true)
        
        // When
        viewModel.setOverlayPause(isPresented: false)
        
        // Then
        XCTAssertFalse(scene.gameState.isPaused, "Game should resume when menu overlay is dismissed")
    }
    
    func testGivenUserPausedGameWhenDismissingOverlayThenGameStaysPaused() {
        // Given
        let imageLoader = MockImageLoader()
        let soundPlayer = MockSoundPlayer()
        let laneCuePlayer = MockLaneCuePlayerStub()
        let scene = GameScene(
            size: CGSize(width: 100, height: 100),
            theme: nil,
            imageLoader: imageLoader,
            soundPlayer: soundPlayer,
            laneCuePlayer: laneCuePlayer,
            hapticController: nil,
            audioFeedbackMode: .retro,
            laneMoveCueStyle: .laneConfirmationAndSafety,
            difficulty: .rapid
        )
        scene.pauseGameplay()
        viewModel.scene = scene
        viewModel.pause.isUserPaused = true
        viewModel.setOverlayPause(isPresented: true)
        
        // When
        viewModel.setOverlayPause(isPresented: false)
        
        // Then
        XCTAssertTrue(scene.gameState.isPaused, "Game should stay paused when user explicitly paused it")
    }
    
    func testGivenMenuOverlayNotPresentedWhenSettingOverlayPauseThenIsMenuOverlayPresentedIsUpdated() {
        // Given
        viewModel.isMenuOverlayPresented = false
        
        // When
        viewModel.setOverlayPause(isPresented: true)
        
        // Then
        XCTAssertTrue(viewModel.isMenuOverlayPresented, "isMenuOverlayPresented should be updated when overlay is presented")
    }
    
    func testGivenSceneNotCreatedWhenSettingOverlayPauseThenDoesNotCrash() {
        // Given
        viewModel.scene = nil
        
        // When
        viewModel.setOverlayPause(isPresented: true)
        
        // Then
        // Test passes if no crash occurs
    }

    func testGivenRunningSceneWhenPresentingAndDismissingManualHelpThenOriginalPauseStateIsRestored() {
        // Given
        let imageLoader = MockImageLoader()
        let soundPlayer = MockSoundPlayer()
        let laneCuePlayer = MockLaneCuePlayerStub()
        let scene = GameScene(
            size: CGSize(width: 100, height: 100),
            theme: nil,
            imageLoader: imageLoader,
            soundPlayer: soundPlayer,
            laneCuePlayer: laneCuePlayer,
            hapticController: nil,
            audioFeedbackMode: .retro,
            laneMoveCueStyle: .laneConfirmationAndSafety,
            difficulty: .rapid
        )
        scene.unpauseGameplay()
        viewModel.scene = scene
        viewModel.pause.scenePaused = false
        viewModel.pause.isUserPaused = false

        // When
        let snapshot = viewModel.beginManualHelpPresentation()
        viewModel.endManualHelpPresentation(using: snapshot)

        // Then
        XCTAssertFalse(scene.gameState.isPaused)
        XCTAssertFalse(viewModel.pause.isUserPaused)
    }

    func testGivenPausedByUserWhenPresentingAndDismissingManualHelpThenPauseStateStaysUserPaused() {
        // Given
        let imageLoader = MockImageLoader()
        let soundPlayer = MockSoundPlayer()
        let laneCuePlayer = MockLaneCuePlayerStub()
        let scene = GameScene(
            size: CGSize(width: 100, height: 100),
            theme: nil,
            imageLoader: imageLoader,
            soundPlayer: soundPlayer,
            laneCuePlayer: laneCuePlayer,
            hapticController: nil,
            audioFeedbackMode: .retro,
            laneMoveCueStyle: .laneConfirmationAndSafety,
            difficulty: .rapid
        )
        scene.pauseGameplay()
        viewModel.scene = scene
        viewModel.pause.scenePaused = true
        viewModel.pause.isUserPaused = true

        // When
        let snapshot = viewModel.beginManualHelpPresentation()
        viewModel.endManualHelpPresentation(using: snapshot)

        // Then
        XCTAssertTrue(scene.gameState.isPaused)
        XCTAssertTrue(viewModel.pause.isUserPaused)
    }

    func testGivenSceneIsRunningWhenTogglingPauseThenSceneBecomesPausedAndUserPauseIsTrue() {
        // Given
        let scene = makeScene()
        scene.unpauseGameplay()
        viewModel.scene = scene

        // When
        viewModel.togglePause()

        // Then
        XCTAssertTrue(scene.gameState.isPaused)
        XCTAssertTrue(viewModel.pause.isUserPaused)
    }

    func testGivenSceneIsUserPausedWhenTogglingPauseThenSceneBecomesUnpausedAndUserPauseIsFalse() {
        // Given
        let scene = makeScene()
        scene.pauseGameplay()
        viewModel.scene = scene
        viewModel.pause.isUserPaused = true

        // When
        viewModel.togglePause()

        // Then
        XCTAssertFalse(scene.gameState.isPaused)
        XCTAssertFalse(viewModel.pause.isUserPaused)
    }

    func testGivenPauseButtonIsDisabledWhenTogglingPauseThenPauseStateDoesNotChange() {
        // Given
        let scene = makeScene()
        scene.pauseGameplay()
        viewModel.scene = scene
        viewModel.pause.scenePaused = true
        viewModel.pause.isUserPaused = false

        // When
        viewModel.togglePause()

        // Then
        XCTAssertTrue(scene.gameState.isPaused)
        XCTAssertFalse(viewModel.pause.isUserPaused)
    }

    func testGivenRatingIsPendingWhenGameOverModalPresentedTwiceThenRatingIsRequestedOnce() {
        // Given
        viewModel.hud.shouldRequestRatingOnGameOverModal = true

        // When
        viewModel.handleGameOverModalPresentedIfNeeded()
        viewModel.handleGameOverModalPresentedIfNeeded()

        // Then
        XCTAssertEqual(ratingService.recordBestScoreImprovementCallCount, 1)
        XCTAssertFalse(viewModel.hud.shouldRequestRatingOnGameOverModal)
    }

    func testGivenRatingIsNotPendingWhenGameOverModalPresentedThenRatingIsNotRequested() {
        // Given
        viewModel.hud.shouldRequestRatingOnGameOverModal = false

        // When
        viewModel.handleGameOverModalPresentedIfNeeded()

        // Then
        XCTAssertEqual(ratingService.recordBestScoreImprovementCallCount, 0)
    }

    func testGivenGameOverVisibleWhenDismissGameOverModalThenModalStateCleared() {
        // Given
        viewModel.hud.showGameOver = true
        viewModel.hud.shouldRequestRatingOnGameOverModal = true
        viewModel.hud.gameOverNewlyAchievedAchievementIDs = [.controlTap]

        // When
        viewModel.dismissGameOverModal()

        // Then
        XCTAssertFalse(viewModel.hud.showGameOver)
        XCTAssertFalse(viewModel.hud.shouldRequestRatingOnGameOverModal)
        XCTAssertTrue(viewModel.hud.gameOverNewlyAchievedAchievementIDs.isEmpty)
    }

    func testGivenRunTelemetryWhenRestartGameThenTapTelemetryIsCleared() {
        // Given
        let scene = makeScene()
        scene.createGrid()
        viewModel.scene = scene
        viewModel.recordControlInput(.tap)

        // When
        viewModel.restartGame()

        // Then
        XCTAssertFalse(viewModel.runInputTelemetry.usedInputs.contains(.tap))
    }

    func testGivenGameControllerTelemetryWhenRestartGameThenControllerTelemetryIsCleared() {
        // Given
        let scene = makeScene()
        scene.createGrid()
        viewModel.scene = scene
        viewModel.recordControlInput(.gameController)

        // When
        viewModel.restartGame()

        // Then
        XCTAssertFalse(viewModel.runInputTelemetry.usedInputs.contains(.gameController))
    }

    func testGivenActiveSpecialEventWhenRestartingGameThenPlayLimitIsNotRecorded() {
        // Given
        let playLimitService = MockPlayLimitServiceForGameViewModel()
        let specialEventService = MockSpecialEventServiceForGameViewModel(isActive: true)
        let viewModel = makeViewModel(
            playLimitService: playLimitService,
            specialEventService: specialEventService
        )

        // When
        viewModel.restartGame()

        // Then
        XCTAssertEqual(playLimitService.recordGamePlayedCallCount, 0)
    }

    func testGivenInactiveSpecialEventWhenRestartingGameThenPlayLimitIsRecorded() {
        // Given
        let playLimitService = MockPlayLimitServiceForGameViewModel()
        let specialEventService = MockSpecialEventServiceForGameViewModel(isActive: false)
        let viewModel = makeViewModel(
            playLimitService: playLimitService,
            specialEventService: specialEventService
        )

        // When
        viewModel.restartGame()

        // Then
        XCTAssertEqual(playLimitService.recordGamePlayedCallCount, 1)
    }

    // MARK: - SharePlay free-play exception (Requirements/monetization.md, "SharePlay Exception")

    func testGivenActiveSharePlayMatchWhenRestartingGameThenPlayLimitIsNotRecorded() {
        // Given
        let playLimitService = MockPlayLimitServiceForGameViewModel()
        let viewModel = makeViewModel(
            playLimitService: playLimitService,
            specialEventService: nil
        )
        viewModel.sharePlayState = .inRound(difficulty: .rapid, localScore: 0, remoteScore: 0, remoteLives: 3)

        // When
        viewModel.restartGame()

        // Then
        XCTAssertEqual(playLimitService.recordGamePlayedCallCount, 0)
    }

    func testGivenActiveSharePlayMatchAtZeroRemainingPlaysWhenRestartingGameThenPlayLimitIsStillNotRecorded() {
        // Given
        let playLimitService = MockPlayLimitServiceForGameViewModel()
        playLimitService.canStartNewGameOverride = false
        playLimitService.remainingPlaysOverride = 0
        let viewModel = makeViewModel(
            playLimitService: playLimitService,
            specialEventService: nil
        )
        viewModel.sharePlayState = .waitingForFriend

        // When
        viewModel.restartGame()

        // Then
        XCTAssertEqual(playLimitService.recordGamePlayedCallCount, 0)
    }

    func testGivenIdleSharePlayStateWhenRestartingGameThenPlayLimitIsRecordedNormally() {
        // Given
        let playLimitService = MockPlayLimitServiceForGameViewModel()
        let viewModel = makeViewModel(
            playLimitService: playLimitService,
            specialEventService: nil
        )
        viewModel.sharePlayState = .idle

        // When
        viewModel.restartGame()

        // Then
        XCTAssertEqual(playLimitService.recordGamePlayedCallCount, 1)
    }

    func testGivenActiveSharePlayMatchWhenHandlingCollisionThenGameOverSheetIsNotShown() {
        // Given
        let scene = makeScene()
        scene.handleCrash()
        scene.handleCrash()
        scene.handleCrash()
        viewModel.scene = scene
        viewModel.sharePlayState = .inRound(difficulty: .rapid, localScore: 10, remoteScore: 5, remoteLives: 2)
        XCTAssertEqual(scene.gameState.lives, 0)

        // When
        viewModel.handleCollision()

        // Then
        XCTAssertFalse(viewModel.hud.showGameOver)
        XCTAssertEqual(viewModel.hud.gameOverScore, scene.gameState.score)
    }

    func testGivenFinalSharePlayCollisionWhenHandlingCollisionThenLivesZeroIsSentBeforeElimination() async {
        // Given
        let sharePlayMatchService = MockSharePlayMatchServiceForGameViewModel()
        let viewModel = makeViewModel(
            playLimitService: nil,
            specialEventService: nil,
            sharePlayMatchService: sharePlayMatchService
        )
        let scene = makeScene()
        scene.handleCrash()
        scene.handleCrash()
        scene.handleCrash()
        viewModel.scene = scene
        viewModel.sharePlayState = .inRound(difficulty: .rapid, localScore: 0, remoteScore: 5, remoteLives: 2)
        XCTAssertEqual(scene.gameState.lives, 0)

        // When
        viewModel.handleCollision()
        await waitForSharePlayEvents(sharePlayMatchService, count: 2)

        // Then
        let events = await sharePlayMatchService.recordedEvents()
        XCTAssertEqual(
            events,
            [
                .scoreUpdate(score: scene.gameState.score, lives: 0),
                .playerEliminated(finalScore: scene.gameState.score)
            ]
        )
    }

    func testGivenGuestSharePlayMatchFinishesWhenApplyingStateThenOriginalDifficultyIsRestored() {
        // Given
        viewModel.selectedDifficulty = .cruise
        viewModel.applySharePlayState(
            SharePlayUIState(
                state: .countdown(startAt: Date().addingTimeInterval(3), difficulty: .rapid),
                localRole: .guest,
                opponentDisplayName: "Rita"
            )
        )
        XCTAssertEqual(viewModel.selectedDifficulty, .rapid)

        // When
        viewModel.applySharePlayState(
            SharePlayUIState(
                state: .finished(SharePlayRoundResult(hostScore: 12, guestScore: 8, difficulty: .rapid)),
                localRole: .guest,
                opponentDisplayName: "Rita"
            )
        )

        // Then
        XCTAssertEqual(viewModel.selectedDifficulty, .cruise)
    }

    func testGivenSharePlayWaitingCountdownAndRecoveryStatesWhenAppliedThenGameplayStaysPaused() {
        // Given
        let scene = makeScene()
        viewModel.scene = scene
        let now = Date(timeIntervalSinceReferenceDate: 1_000)
        let pausedStates: [SharePlayMatchState] = [
            .waitingForFriend,
            .countdown(startAt: now.addingTimeInterval(3), difficulty: .rapid),
            .waitingAfterLocalLoss(remoteScore: 12, localFinalScore: 8),
            .finished(SharePlayRoundResult(hostScore: 12, guestScore: 8, difficulty: .rapid)),
            .retryWaiting(localReady: false, remoteReady: false, deadline: now.addingTimeInterval(30)),
            .retryTimedOut,
            .aborted(reason: .disconnected)
        ]

        for state in pausedStates {
            // When
            scene.unpauseGameplay()
            viewModel.applySharePlayState(
                SharePlayUIState(state: state, localRole: .host, opponentDisplayName: "Rita")
            )

            // Then
            XCTAssertTrue(scene.gameState.isPaused, "\(state) should keep gameplay paused")
        }
    }

    func testGivenActiveEventWhenEvaluatingSupportButtonPolicyThenSupportButtonIsShown() {
        // Given
        let showRateButton = true
        let shouldShowFreeTierAffordances = true

        // When
        let shouldShowButton = MenuView.shouldShowSupportButtonPolicy(
            showRateButton: showRateButton,
            shouldShowFreeTierAffordances: shouldShowFreeTierAffordances
        )

        // Then
        XCTAssertTrue(shouldShowButton)
    }

    func testGivenEligibleFreeUserWithoutEventWhenEvaluatingSupportButtonPolicyThenSupportButtonIsShown() {
        // Given
        let showRateButton = true
        let shouldShowFreeTierAffordances = true

        // When
        let shouldShowButton = MenuView.shouldShowSupportButtonPolicy(
            showRateButton: showRateButton,
            shouldShowFreeTierAffordances: shouldShowFreeTierAffordances
        )

        // Then
        XCTAssertTrue(shouldShowButton)
    }

    func testGivenNoFreeTierAffordancesWhenEvaluatingSupportButtonPolicyThenSupportButtonIsHidden() {
        // Given
        let showRateButton = true
        let shouldShowFreeTierAffordances = false

        // When
        let shouldShowButton = MenuView.shouldShowSupportButtonPolicy(
            showRateButton: showRateButton,
            shouldShowFreeTierAffordances: shouldShowFreeTierAffordances
        )

        // Then
        XCTAssertFalse(shouldShowButton)
    }

    func testGivenPremiumGatingWhenEvaluatingRateButtonPolicyThenRateButtonIsHidden() {
        // Given
        let showRateButton = true
        let hasPremiumAccessForGating = true

        // When
        let shouldShowButton = MenuView.shouldShowRateButtonPolicy(
            showRateButton: showRateButton,
            hasPremiumAccessForGating: hasPremiumAccessForGating
        )

        // Then
        XCTAssertFalse(shouldShowButton)
    }

    func testGivenNonPremiumGatingWhenEvaluatingRateButtonPolicyThenRateButtonIsShown() {
        // Given
        let showRateButton = true
        let hasPremiumAccessForGating = false

        // When
        let shouldShowButton = MenuView.shouldShowRateButtonPolicy(
            showRateButton: showRateButton,
            hasPremiumAccessForGating: hasPremiumAccessForGating
        )

        // Then
        XCTAssertTrue(shouldShowButton)
    }

    func testGivenCachedPremiumGatingWhenEvaluatingRateButtonPolicyThenRateButtonIsHidden() {
        // Given
        let showRateButton = true
        let hasPremiumAccessForGating = true

        // When
        let shouldShowButton = MenuView.shouldShowRateButtonPolicy(
            showRateButton: showRateButton,
            hasPremiumAccessForGating: hasPremiumAccessForGating
        )

        // Then
        XCTAssertFalse(shouldShowButton)
    }

    func testGivenPlatformHidesRateButtonWhenEvaluatingRateButtonPolicyThenRateButtonIsHidden() {
        // Given
        let showRateButton = false
        let hasPremiumAccessForGating = false

        // When
        let shouldShowButton = MenuView.shouldShowRateButtonPolicy(
            showRateButton: showRateButton,
            hasPremiumAccessForGating: hasPremiumAccessForGating
        )

        // Then
        XCTAssertFalse(shouldShowButton)
    }

    func testGivenGameOverWhenHandlingCollisionThenAchievementProgressRecordsCompletedRun() {
        // Given
        let scene = makeScene()
        scene.handleCrash()
        scene.handleCrash()
        scene.handleCrash()
        viewModel.scene = scene
        viewModel.recordControlInput(.tap)
        let expectedOvertakes = scene.gameState.score
        XCTAssertEqual(scene.gameState.lives, 0)

        // When
        viewModel.handleCollision()

        // Then
        XCTAssertEqual(achievementProgressService.recordedRuns.count, 1)
        XCTAssertEqual(achievementProgressService.recordedRuns.first?.overtakes, expectedOvertakes)
        XCTAssertTrue(achievementProgressService.recordedRuns.first?.usedControls.contains(.tap) ?? false)
    }

    func testGivenGameOverWhenHandlingCollisionAfterControllerInputThenAchievementProgressIncludesControllerUsage() {
        // Given
        let scene = makeScene()
        scene.handleCrash()
        scene.handleCrash()
        scene.handleCrash()
        viewModel.scene = scene
        viewModel.recordControlInput(.gameController)
        XCTAssertEqual(scene.gameState.lives, 0)

        // When
        viewModel.handleCollision()

        // Then
        XCTAssertEqual(achievementProgressService.recordedRuns.count, 1)
        XCTAssertTrue(achievementProgressService.recordedRuns.first?.usedControls.contains(.gameController) ?? false)
    }

    func testGivenGameOverWhenHandlingCollisionAfterSwitchControlTelemetryThenAchievementProgressIncludesAssistiveTelemetry() {
        // Given
        let scene = makeScene()
        scene.handleCrash()
        scene.handleCrash()
        scene.handleCrash()
        viewModel.scene = scene
        viewModel.runInputTelemetry.recordAssistiveTechnology(.switchControl)
        XCTAssertEqual(scene.gameState.lives, 0)

        // When
        viewModel.handleCollision()

        // Then
        XCTAssertEqual(achievementProgressService.recordedRuns.count, 1)
        XCTAssertTrue(achievementProgressService.recordedRuns.first?.activeAssistiveTechnologies.contains(.switchControl) ?? false)
    }

    func testGivenGameOverWithNewAchievementsWhenHandlingCollisionThenGameOverStateStoresNewAchievementIDs() {
        // Given
        let scene = makeScene()
        scene.handleCrash()
        scene.handleCrash()
        scene.handleCrash()
        viewModel.scene = scene
        achievementProgressService.newlyAchievedAchievementIDsToReturn = [.eventGAADAssistive, .controlTap]
        XCTAssertEqual(scene.gameState.lives, 0)

        // When
        viewModel.handleCollision()

        // Then
        XCTAssertEqual(
            viewModel.hud.gameOverNewlyAchievedAchievementIDs,
            [.controlTap, .eventGAADAssistive]
        )
    }

    func testGivenDebugForcedAchievementWhenHandlingCollisionThenForcedAchievementAppearsInGameOverList() {
        // Given
        let scene = makeScene()
        scene.handleCrash()
        scene.handleCrash()
        scene.handleCrash()
        viewModel.scene = scene
        viewModel.setDebugForcedAchievementIdentifier(.controlGameController)
        XCTAssertEqual(scene.gameState.lives, 0)

        // When
        viewModel.handleCollision()

        // Then
        XCTAssertEqual(viewModel.hud.gameOverNewlyAchievedAchievementIDs, [.controlGameController])
    }

    func testGivenDebugForcedAchievementAlreadyInNewAchievementsWhenHandlingCollisionThenAchievementIsNotDuplicated() {
        // Given
        let scene = makeScene()
        scene.handleCrash()
        scene.handleCrash()
        scene.handleCrash()
        viewModel.scene = scene
        viewModel.setDebugForcedAchievementIdentifier(.controlGameController)
        achievementProgressService.newlyAchievedAchievementIDsToReturn = [.controlGameController]
        XCTAssertEqual(scene.gameState.lives, 0)

        // When
        viewModel.handleCollision()

        // Then
        XCTAssertEqual(viewModel.hud.gameOverNewlyAchievedAchievementIDs, [.controlGameController])
    }

    func testGivenRemoteBestInFriendSnapshotWhenRefreshingMilestonesThenBaselineUsesRemoteBest() async {
        // Given
        leaderboardService.friendSnapshotsByDifficulty[.rapid] = FriendLeaderboardSnapshot(
            remoteBestScore: 120,
            friendEntries: [
                FriendLeaderboardEntry(playerID: "p1", displayName: "Alex", score: 130)
            ]
        )
        _ = highestScoreStore.updateIfHigher(80, for: .rapid)

        // When
        await viewModel.refreshFriendMilestonesForCurrentRun()

        // Then
        XCTAssertEqual(viewModel.runBaselineBestScore, 120)
    }

    func testGivenMissingRemoteBestWhenRefreshingMilestonesThenBaselineFallsBackToLocalBest() async {
        // Given
        leaderboardService.friendSnapshotsByDifficulty[.rapid] = FriendLeaderboardSnapshot(
            remoteBestScore: nil,
            friendEntries: [
                FriendLeaderboardEntry(playerID: "p1", displayName: "Alex", score: 130)
            ]
        )
        _ = highestScoreStore.updateIfHigher(90, for: .rapid)

        // When
        await viewModel.refreshFriendMilestonesForCurrentRun()

        // Then
        XCTAssertEqual(viewModel.runBaselineBestScore, 90)
    }

    func testGivenOlderDifficultyRefreshCompletesAfterNewerRefreshWhenRefreshingMilestonesThenStaleResultIsIgnored() async {
        // Given
        leaderboardService.friendSnapshotsByDifficulty[.rapid] = FriendLeaderboardSnapshot(
            remoteBestScore: 120,
            friendEntries: [
                FriendLeaderboardEntry(playerID: "p1", displayName: "Alex", score: 130)
            ]
        )
        leaderboardService.friendSnapshotsByDifficulty[.cruise] = FriendLeaderboardSnapshot(
            remoteBestScore: 260,
            friendEntries: [
                FriendLeaderboardEntry(playerID: "p2", displayName: "Rita", score: 280)
            ]
        )
        leaderboardService.friendSnapshotDelayByDifficultyNanoseconds[.rapid] = 250_000_000
        viewModel.selectedDifficulty = .rapid

        // When
        let olderRefresh = Task {
            await viewModel.refreshFriendMilestonesForCurrentRun()
        }
        viewModel.selectedDifficulty = .cruise
        await viewModel.refreshFriendMilestonesForCurrentRun()
        _ = await olderRefresh.result

        // Then
        XCTAssertEqual(viewModel.runBaselineBestScore, 260)
        XCTAssertEqual(viewModel.friendSnapshot?.remoteBestScore, 260)
    }

    func testGivenFriendMilestonesWhenScoreAdvancesThenUpcomingMilestoneProgresses() async {
        // Given
        leaderboardService.friendSnapshotsByDifficulty[.rapid] = FriendLeaderboardSnapshot(
            remoteBestScore: 100,
            friendEntries: [
                FriendLeaderboardEntry(playerID: "p1", displayName: "Alex", score: 110),
                FriendLeaderboardEntry(playerID: "p2", displayName: "Rita", score: 130)
            ]
        )
        await viewModel.refreshFriendMilestonesForCurrentRun()

        // When
        viewModel.updateFriendProgress(forScore: 115)

        // Then
        XCTAssertEqual(viewModel.currentUpcomingFriendMilestone?.targetScore, 130)
    }

    func testGivenNewlyOvertakenFriendWhenUpdatingProgressThenPendingAnnouncementUsesFriendName() {
        // Given
        viewModel.friendSnapshot = FriendLeaderboardSnapshot(
            remoteBestScore: 90,
            friendEntries: [
                FriendLeaderboardEntry(playerID: "p1", displayName: "Alex", score: 100)
            ]
        )
        viewModel.runBaselineBestScore = 90
        viewModel.overtakenFriendPlayerIDs = []

        // When
        viewModel.updateFriendProgress(forScore: 100)
        let announcement = viewModel.consumePendingFriendOvertakeAnnouncement()

        // Then
        XCTAssertEqual(
            announcement,
            GameLocalizedStrings.format("friend_overtake_announcement %@", "Alex")
        )
        XCTAssertNil(viewModel.consumePendingFriendOvertakeAnnouncement())
    }

    func testGivenMultipleNewlyOvertakenFriendsWhenUpdatingProgressThenPendingAnnouncementUsesCount() {
        // Given
        viewModel.friendSnapshot = FriendLeaderboardSnapshot(
            remoteBestScore: 100,
            friendEntries: [
                FriendLeaderboardEntry(playerID: "p1", displayName: "Alex", score: 101),
                FriendLeaderboardEntry(playerID: "p2", displayName: "Rita", score: 102)
            ]
        )
        viewModel.runBaselineBestScore = 100
        viewModel.overtakenFriendPlayerIDs = []

        // When
        viewModel.updateFriendProgress(forScore: 102)
        let announcement = viewModel.consumePendingFriendOvertakeAnnouncement()

        // Then
        XCTAssertEqual(
            announcement,
            GameLocalizedStrings.format("friend_overtake_announcement_multiple %lld", Int64(2))
        )
    }

    func testGivenBaselineHigherThanFriendScoreWhenRefreshingMilestonesThenInRunUpcomingFriendStillAppears() async {
        // Given
        leaderboardService.friendSnapshotsByDifficulty[.rapid] = FriendLeaderboardSnapshot(
            remoteBestScore: 200,
            friendEntries: [
                FriendLeaderboardEntry(playerID: "p1", displayName: "Alex", score: 136),
                FriendLeaderboardEntry(playerID: "p2", displayName: "Rita", score: 220)
            ]
        )

        // When
        await viewModel.refreshFriendMilestonesForCurrentRun()
        viewModel.updateFriendProgress(forScore: 130)

        // Then
        XCTAssertEqual(viewModel.currentUpcomingFriendMilestone?.targetScore, 136)
    }

    func testGivenFriendMilestonesWhenApplyingGameOverSummariesThenNextAheadAndOvertakenAreComputed() async {
        // Given
        leaderboardService.friendSnapshotsByDifficulty[.rapid] = FriendLeaderboardSnapshot(
            remoteBestScore: 100,
            friendEntries: [
                FriendLeaderboardEntry(playerID: "p1", displayName: "Alex", score: 110),
                FriendLeaderboardEntry(playerID: "p2", displayName: "Rita", score: 120),
                FriendLeaderboardEntry(playerID: "p3", displayName: "Marta", score: 150)
            ]
        )
        await viewModel.refreshFriendMilestonesForCurrentRun()

        // When
        viewModel.applyFriendGameOverSummaries(finalScore: 125)

        // Then
        XCTAssertEqual(viewModel.hud.gameOverNextFriendAhead?.playerID, "p3")
        XCTAssertEqual(viewModel.hud.gameOverOvertakenFriends.map(\.playerID), ["p1", "p2"])
    }

    func testGivenSharePlayResultSocialStatsWhenFriendStateClearsThenSnapshotRemainsStable() {
        // Given
        viewModel.friendSnapshot = FriendLeaderboardSnapshot(
            remoteBestScore: 100,
            friendEntries: [
                FriendLeaderboardEntry(playerID: "p1", displayName: "Alex", score: 110),
                FriendLeaderboardEntry(playerID: "p2", displayName: "Rita", score: 120),
                FriendLeaderboardEntry(playerID: "p3", displayName: "Marta", score: 150)
            ]
        )
        viewModel.runBaselineBestScore = 100
        viewModel.applySharePlayState(
            SharePlayUIState(
                state: .waitingAfterLocalLoss(remoteScore: 90, localFinalScore: 125),
                localRole: .host,
                opponentDisplayName: "Rita"
            )
        )
        let capturedStats = viewModel.sharePlayResultSocialStats

        // When
        viewModel.clearFriendMilestoneState()
        viewModel.applySharePlayState(
            SharePlayUIState(
                state: .finished(SharePlayRoundResult(hostScore: 125, guestScore: 140, difficulty: .rapid)),
                localRole: .host,
                opponentDisplayName: "Rita"
            )
        )

        // Then
        XCTAssertNil(viewModel.hud.gameOverNextFriendAhead)
        XCTAssertEqual(capturedStats?.nextFriendAhead?.playerID, "p3")
        XCTAssertEqual(capturedStats?.overtakenFriends.map(\.playerID), ["p1", "p2"])
        XCTAssertEqual(viewModel.sharePlayResultSocialStats, capturedStats)
    }

    func testGivenSharePlayResultSocialStatsWhenRetryStartsThenSnapshotClears() {
        // Given
        viewModel.sharePlayResultSocialStats = GameOverSocialStatsSummary(
            nextFriendAhead: GameOverFriendAheadSummary(
                playerID: "p1",
                displayName: "Alex",
                score: 150,
                avatarPNGData: nil
            ),
            overtakenFriends: []
        )

        // When
        viewModel.applySharePlayState(
            SharePlayUIState(
                state: .retryWaiting(
                    localReady: true,
                    remoteReady: false,
                    deadline: Date(timeIntervalSinceReferenceDate: 1_000)
                ),
                localRole: .host,
                opponentDisplayName: "Rita"
            )
        )

        // Then
        XCTAssertNil(viewModel.sharePlayResultSocialStats)
    }

    private func makeScene() -> GameScene {
        GameScene(
            size: CGSize(width: 100, height: 100),
            theme: nil,
            imageLoader: MockImageLoader(),
            soundPlayer: MockSoundPlayer(),
            laneCuePlayer: MockLaneCuePlayerStub(),
            hapticController: nil,
            audioFeedbackMode: .retro,
            laneMoveCueStyle: .laneConfirmationAndSafety,
            difficulty: .rapid
        )
    }

    private func makeViewModel(
        playLimitService: PlayLimitService?,
        specialEventService: SpecialEventService?,
        sharePlayMatchService: (any SharePlayMatchService)? = nil
    ) -> GameViewModel {
        GameViewModel(
            leaderboardService: leaderboardService,
            ratingService: ratingService,
            theme: nil,
            hapticController: nil,
            highestScoreStore: highestScoreStore,
            achievementProgressService: achievementProgressService,
            inputAdapterFactory: inputAdapterFactory,
            playLimitService: playLimitService,
            specialEventService: specialEventService,
            sharePlayMatchService: sharePlayMatchService,
            selectedDifficulty: .rapid,
            selectedAudioFeedbackMode: .retro,
            selectedLaneMoveCueStyle: .laneConfirmationAndSafety,
            selectedBigRivalCarsEnabled: false,
            selectedRoadVisualStyle: .detailedRoad,
            shouldStartGame: true
        )
    }

    private func waitForSharePlayEvents(
        _ service: MockSharePlayMatchServiceForGameViewModel,
        count: Int,
        maxYields: Int = 10
    ) async {
        for _ in 0..<maxYields {
            if await service.recordedEvents().count >= count {
                return
            }
            await Task.yield()
        }
    }
}

// MARK: - Mock Objects

private final class MockRatingService: RatingService {
    private(set) var requestRatingCallCount = 0
    private(set) var recordBestScoreImprovementCallCount = 0

    func requestRating() {
        requestRatingCallCount += 1
    }

    func recordBestScoreImprovementAndRequestIfEligible() {
        recordBestScoreImprovementCallCount += 1
    }
}

private final class MockHighestScoreStore: HighestScoreStore {
    private(set) var highestScores: [GameDifficulty: Int] = [:]

    func currentBest(for difficulty: GameDifficulty) -> Int {
        highestScores[difficulty, default: 0]
    }

    func updateIfHigher(_ score: Int, for difficulty: GameDifficulty) -> Bool {
        let existing = highestScores[difficulty, default: 0]
        guard score > existing else { return false }
        highestScores[difficulty] = score
        return true
    }

    func syncFromRemote(bestScore: Int, for difficulty: GameDifficulty) {
        let existing = highestScores[difficulty, default: 0]
        if bestScore > existing {
            highestScores[difficulty] = bestScore
        }
    }
}

private final class MockInputAdapterFactory: GameInputAdapterFactory {
    func makeAdapter(controller: RacingGameController, hapticController: HapticFeedbackController?) -> GameInputAdapter {
        MockInputAdapter()
    }
}

private struct MockInputAdapter: GameInputAdapter {
    func handleLeft() {}
    func handleRight() {}
    func handleDrag(translation: CGSize) {}
}

private final class MockImageLoader: ImageLoader {
    func loadTexture(imageNamed name: String, bundle: Bundle) -> SKTexture {
        SKTexture()
    }
}

private final class MockSoundPlayer: SoundEffectPlayer {
    func play(_ effect: SoundEffect, completion: (() -> Void)?) {
        completion?()
    }
    
    func setVolume(_ volume: Double) {}
    func stopAll(fadeDuration: TimeInterval) {}
}

private final class MockLaneCuePlayerStub: LaneCuePlayer {
    func playTickCue(safeColumns: Set<CueColumn>, mode: AudioFeedbackMode) {}
    func playMoveCue(column: CueColumn, isSafe: Bool, mode: AudioFeedbackMode, style: LaneMoveCueStyle) {}
    func playSpeedWarningCue() {}
    func setVolume(_ volume: Double) {}
    func stopAll(fadeDuration: TimeInterval) {}
}

private actor MockSharePlayMatchServiceForGameViewModel: SharePlayMatchService {
    enum Event: Equatable {
        case scoreUpdate(score: Int, lives: Int)
        case playerEliminated(finalScore: Int)
        case retry
        case leave
        case cancelHostActivation
    }

    private var events: [Event] = []
    private var stateChangeHandler: (@Sendable (SharePlayMatchState) -> Void)?

    func recordedEvents() -> [Event] {
        events
    }

    func setStateChangeHandler(_ handler: @escaping @Sendable (SharePlayMatchState) -> Void) async {
        stateChangeHandler = handler
    }

    func currentRole() async -> SharePlayPlayerRole? {
        .host
    }

    func startHostSession() async {}

    func prepareHostActivation() async {}

    func cancelHostActivation() async {
        events.append(.cancelHostActivation)
    }

    func observeIncomingSessions() async {}

    func hostStartRoundIfReady(difficulty: GameDifficulty) async {}

    func updateLocalScore(_ score: Int, lives: Int) async {
        events.append(.scoreUpdate(score: score, lives: lives))
    }

    func currentOpponentDisplayName() async -> String? {
        nil
    }

    func reportLocalElimination(finalScore: Int) async {
        events.append(.scoreUpdate(score: finalScore, lives: 0))
        events.append(.playerEliminated(finalScore: finalScore))
    }

    func retry() async {
        events.append(.retry)
    }

    func leaveSession() async {
        events.append(.leave)
    }
}

private final class MockAchievementProgressService: AchievementProgressService {
    private(set) var backfillCallCount = 0
    private(set) var recordedRuns: [CompletedRunAchievementData] = []
    var snapshot = AchievementProgressSnapshot.empty
    var newlyAchievedAchievementIDsToReturn = Set<AchievementIdentifier>()

    func performInitialBackfillIfNeeded() {
        backfillCallCount += 1
    }

    @discardableResult
    func recordCompletedRun(_ run: CompletedRunAchievementData) -> AchievementProgressUpdate {
        recordedRuns.append(run)
        snapshot.bestRunOvertakes = max(snapshot.bestRunOvertakes, run.overtakes)
        snapshot.cumulativeOvertakes += max(0, run.overtakes)
        snapshot.lifetimeUsedControls.formUnion(run.usedControls)
        return AchievementProgressUpdate(
            snapshot: snapshot,
            newlyAchievedAchievementIDs: newlyAchievedAchievementIDsToReturn
        )
    }

    func replayAchievedAchievements() {}

    func currentProgress() -> AchievementProgressSnapshot {
        snapshot
    }
}

private final class MockPlayLimitServiceForGameViewModel: PlayLimitService {
    private(set) var recordGamePlayedCallCount = 0
    private(set) var hasUnlimitedAccess = false
    /// Overridable so tests can simulate a player who has exhausted their daily plays.
    var canStartNewGameOverride = true
    var remainingPlaysOverride = 3

    func canStartNewGame(on date: Date) -> Bool {
        canStartNewGameOverride
    }

    func recordGamePlayed(on date: Date) {
        recordGamePlayedCallCount += 1
    }

    func remainingPlays(on date: Date) -> Int {
        remainingPlaysOverride
    }

    func maxPlays(on date: Date) -> Int {
        3
    }

    func isFirstPlayDay(on date: Date) -> Bool {
        false
    }

    func nextResetDate(after date: Date) -> Date {
        date.addingTimeInterval(3600)
    }

    func unlockUnlimitedAccess() {
        hasUnlimitedAccess = true
    }

    func clearUnlimitedAccess() {
        hasUnlimitedAccess = false
    }
}

private struct MockSpecialEventServiceForGameViewModel: SpecialEventService {
    let isActive: Bool

    func isEventActive(on date: Date) -> Bool {
        isActive
    }

    func eventInfo(on date: Date) -> SpecialEventInfo? {
        guard isActive else { return nil }
        return SpecialEventInfo(
            name: "Test Event",
            startDate: date,
            inclusiveEndDate: date
        )
    }
}
