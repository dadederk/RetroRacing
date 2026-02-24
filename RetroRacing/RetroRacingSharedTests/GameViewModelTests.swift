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
    private var inputAdapterFactory: MockInputAdapterFactory!
    private var viewModel: GameViewModel!
    
    override func setUp() {
        super.setUp()
        leaderboardService = MockLeaderboardService()
        ratingService = MockRatingService()
        highestScoreStore = MockHighestScoreStore()
        inputAdapterFactory = MockInputAdapterFactory()
        viewModel = GameViewModel(
            leaderboardService: leaderboardService,
            ratingService: ratingService,
            theme: nil,
            hapticController: nil,
            highestScoreStore: highestScoreStore,
            inputAdapterFactory: inputAdapterFactory,
            playLimitService: nil,
            selectedDifficulty: .rapid,
            selectedAudioFeedbackMode: .retro,
            selectedLaneMoveCueStyle: .laneConfirmationAndSafety,
            shouldStartGame: true
        )
    }
    
    override func tearDown() {
        viewModel = nil
        inputAdapterFactory = nil
        highestScoreStore = nil
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

        // When
        viewModel.dismissGameOverModal()

        // Then
        XCTAssertFalse(viewModel.hud.showGameOver)
        XCTAssertFalse(viewModel.hud.shouldRequestRatingOnGameOverModal)
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
