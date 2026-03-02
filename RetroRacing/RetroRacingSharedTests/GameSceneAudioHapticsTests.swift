import XCTest
import SpriteKit
@testable import RetroRacingShared

@MainActor
final class GameSceneAudioHapticsTests: XCTestCase {
    private var soundPlayer: MockSoundEffectPlayer!
    private var laneCuePlayer: MockLaneCuePlayer!
    private var haptics: MockHapticFeedbackController!
    private var scene: GameScene!
    private var delegate: MockGameSceneDelegate!
    private var skView: SKView!

    override func setUp() {
        super.setUp()
        soundPlayer = MockSoundEffectPlayer()
        laneCuePlayer = MockLaneCuePlayer()
        haptics = MockHapticFeedbackController()
        let loader = PlatformFactories.makeImageLoader()
        scene = GameScene.scene(
            size: CGSize(width: 200, height: 200),
            difficulty: .rapid,
            theme: nil,
            imageLoader: loader,
            soundPlayer: soundPlayer,
            laneCuePlayer: laneCuePlayer,
            hapticController: haptics,
            audioFeedbackMode: .retro
        )
        delegate = MockGameSceneDelegate(haptics: haptics)
        scene.gameDelegate = delegate
        skView = SKView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
        skView.presentScene(scene)
    }

    override func tearDown() {
        skView = nil
        delegate = nil
        scene = nil
        haptics = nil
        laneCuePlayer = nil
        soundPlayer = nil
        super.tearDown()
    }

    func testGivenRunningSceneWhenHandlingLeftInputThenRetroMoveCueAndMoveHapticAreTriggered() {
        // Given
        let adapter = TouchGameInputAdapter(controller: scene, hapticController: haptics)

        // When
        adapter.handleLeft()

        // Then
        XCTAssertEqual(soundPlayer.playedEffects, [.start])
        XCTAssertEqual(laneCuePlayer.moveCalls, 1)
        XCTAssertEqual(laneCuePlayer.lastMoveColumn, .middle)
        XCTAssertEqual(laneCuePlayer.lastMoveCueStyle, .laneConfirmation)
        XCTAssertEqual(laneCuePlayer.lastMode, .cueArpeggio)
        XCTAssertEqual(delegate.gridUpdatesCount, 0, "Move should not notify grid update delegate")
        XCTAssertEqual(haptics.moves, 1)
        XCTAssertEqual(haptics.gridUpdates, 0)
    }

    func testGivenRunningSceneWhenRemoteHandlingLeftInputThenRetroMoveCueAndMoveHapticAreTriggered() {
        // Given
        let adapter = RemoteGameInputAdapter(controller: scene, hapticController: haptics)

        // When
        adapter.handleLeft()

        // Then
        XCTAssertEqual(soundPlayer.playedEffects, [.start])
        XCTAssertEqual(laneCuePlayer.moveCalls, 1)
        XCTAssertEqual(laneCuePlayer.lastMoveColumn, .middle)
        XCTAssertEqual(laneCuePlayer.lastMoveCueStyle, .laneConfirmation)
        XCTAssertEqual(laneCuePlayer.lastMode, .cueArpeggio)
        XCTAssertEqual(haptics.moves, 1)
    }

    func testGivenRunningSceneWhenCrownHandlingLeftInputThenRetroMoveCueAndMoveHapticAreTriggered() {
        // Given
        let adapter = CrownGameInputAdapter(controller: scene, hapticController: haptics)

        // When
        adapter.handleLeft()

        // Then
        XCTAssertEqual(soundPlayer.playedEffects, [.start])
        XCTAssertEqual(laneCuePlayer.moveCalls, 1)
        XCTAssertEqual(laneCuePlayer.lastMoveColumn, .middle)
        XCTAssertEqual(laneCuePlayer.lastMoveCueStyle, .laneConfirmation)
        XCTAssertEqual(laneCuePlayer.lastMode, .cueArpeggio)
        XCTAssertEqual(haptics.moves, 1)
    }

    func testGivenRetroModeWithoutLaneCuePlayerWhenHandlingMoveThenBipFallbackIsNotUsed() {
        // Given
        let fallbackSoundPlayer = MockSoundEffectPlayer()
        let fallbackHaptics = MockHapticFeedbackController()
        let loader = PlatformFactories.makeImageLoader()
        let fallbackScene = GameScene.scene(
            size: CGSize(width: 200, height: 200),
            difficulty: .rapid,
            theme: nil,
            imageLoader: loader,
            soundPlayer: fallbackSoundPlayer,
            laneCuePlayer: nil,
            hapticController: fallbackHaptics,
            audioFeedbackMode: .retro
        )
        let fallbackView = SKView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
        fallbackView.presentScene(fallbackScene)
        let adapter = TouchGameInputAdapter(controller: fallbackScene, hapticController: fallbackHaptics)
        let baselineEffects = fallbackSoundPlayer.playedEffects

        // When
        adapter.handleLeft()

        // Then
        XCTAssertEqual(fallbackSoundPlayer.playedEffects, baselineEffects)
        XCTAssertEqual(fallbackHaptics.moves, 1)
    }

    func testGivenCueModeWithoutLaneCuePlayerWhenHandlingMoveThenBipFallbackIsNotUsed() {
        // Given
        let fallbackSoundPlayer = MockSoundEffectPlayer()
        let fallbackHaptics = MockHapticFeedbackController()
        let loader = PlatformFactories.makeImageLoader()
        let fallbackScene = GameScene.scene(
            size: CGSize(width: 200, height: 200),
            difficulty: .rapid,
            theme: nil,
            imageLoader: loader,
            soundPlayer: fallbackSoundPlayer,
            laneCuePlayer: nil,
            hapticController: fallbackHaptics,
            audioFeedbackMode: .cueArpeggio
        )
        let fallbackView = SKView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
        fallbackView.presentScene(fallbackScene)
        let adapter = TouchGameInputAdapter(controller: fallbackScene, hapticController: fallbackHaptics)
        let baselineEffects = fallbackSoundPlayer.playedEffects

        // When
        adapter.handleLeft()

        // Then
        XCTAssertEqual(fallbackSoundPlayer.playedEffects, baselineEffects)
        XCTAssertEqual(fallbackHaptics.moves, 1)
    }

    func testGivenCueModeWithoutLaneCuePlayerWhenPlayingTickThenNoFallbackSoundIsUsed() {
        // Given
        let fallbackSoundPlayer = MockSoundEffectPlayer()
        let loader = PlatformFactories.makeImageLoader()
        let fallbackScene = GameScene.scene(
            size: CGSize(width: 200, height: 200),
            difficulty: .rapid,
            theme: nil,
            imageLoader: loader,
            soundPlayer: fallbackSoundPlayer,
            laneCuePlayer: nil,
            hapticController: nil,
            audioFeedbackMode: .cueArpeggio
        )
        let baselineEffects = fallbackSoundPlayer.playedEffects

        // When
        fallbackScene.playFeedback(event: .tick)

        // Then
        XCTAssertEqual(fallbackSoundPlayer.playedEffects, baselineEffects)
    }

    func testGivenRetroModeWithoutLaneCuePlayerWhenPlayingTickThenNoFallbackSoundIsUsed() {
        // Given
        let fallbackSoundPlayer = MockSoundEffectPlayer()
        let loader = PlatformFactories.makeImageLoader()
        let fallbackScene = GameScene.scene(
            size: CGSize(width: 200, height: 200),
            difficulty: .rapid,
            theme: nil,
            imageLoader: loader,
            soundPlayer: fallbackSoundPlayer,
            laneCuePlayer: nil,
            hapticController: nil,
            audioFeedbackMode: .retro
        )
        let baselineEffects = fallbackSoundPlayer.playedEffects

        // When
        fallbackScene.playFeedback(event: .tick)

        // Then
        XCTAssertEqual(fallbackSoundPlayer.playedEffects, baselineEffects)
    }

    func testGivenRunningSceneAtLeftBoundaryWhenCrownHandlingLeftInputThenMoveHapticIsNotTriggered() {
        // Given
        scene.unpauseGameplay()
        scene.gridState.grid = [
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Car, .Empty],
            [.Player, .Empty, .Empty]
        ]
        scene.lastPlayerColumn = 0
        let adapter = CrownGameInputAdapter(controller: scene, hapticController: haptics)
        let baselineMoves = haptics.moves

        // When
        adapter.handleLeft()

        // Then
        XCTAssertEqual(haptics.moves, baselineMoves)
    }

    func testGivenPausedSceneWhenHandlingLeftInputThenMoveHapticIsTriggeredButSoundIsNot() {
        // Given
        let adapter = TouchGameInputAdapter(controller: scene, hapticController: haptics)
        scene.pauseGameplay()
        let baselineMoves = haptics.moves
        let baselineEffects = soundPlayer.playedEffects

        // When
        adapter.handleLeft()

        // Then
        XCTAssertEqual(haptics.moves, baselineMoves + 1)
        XCTAssertEqual(soundPlayer.playedEffects, baselineEffects)
    }

    func testGivenRunningSceneWhenUpdatingBeyondThresholdThenRetroTickCueAndHapticAreTriggered() {
        // Given

        // When
        scene.update(1.0) // dt > initial threshold

        // Then
        XCTAssertFalse(soundPlayer.playedEffects.contains(.bip))
        XCTAssertEqual(laneCuePlayer.tickCalls, 1)
        XCTAssertEqual(laneCuePlayer.lastTickSafeColumns, Set(CueColumn.allCases))
        XCTAssertEqual(laneCuePlayer.lastMode, .cueArpeggio)
        XCTAssertEqual(delegate.gridUpdatesCount, 1)
        XCTAssertEqual(haptics.gridUpdates, 1)
    }

    func testGivenCueAudioModeWhenUpdatingBeyondThresholdThenTickCueIsTriggeredWithoutBip() {
        // Given
        scene.setAudioFeedbackMode(.cueChord)

        // When
        scene.update(1.0)

        // Then
        XCTAssertFalse(soundPlayer.playedEffects.contains(.bip))
        XCTAssertEqual(laneCuePlayer.tickCalls, 1)
        XCTAssertEqual(laneCuePlayer.moveCalls, 0)
    }

    func testGivenCueLanePulsesModeWhenPlayingTickFeedbackThenSafeColumnsAheadAreForwarded() {
        // Given
        scene.setAudioFeedbackMode(.cueLanePulses)
        scene.gridState.grid = [
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Car, .Empty, .Car],
            [.Empty, .Player, .Empty]
        ]
        let baselineEffects = soundPlayer.playedEffects

        // When
        scene.playFeedback(event: .tick)

        // Then
        XCTAssertEqual(laneCuePlayer.tickCalls, 1)
        XCTAssertEqual(laneCuePlayer.lastMode, .cueLanePulses)
        XCTAssertEqual(laneCuePlayer.lastTickSafeColumns, Set([.middle]))
        XCTAssertEqual(soundPlayer.playedEffects, baselineEffects)
    }

    func testGivenCueAudioModeWhenHandlingMoveThenMoveCueIsTriggeredWithoutBip() {
        // Given
        scene.setAudioFeedbackMode(.cueChord)
        let adapter = TouchGameInputAdapter(controller: scene, hapticController: haptics)

        // When
        adapter.handleLeft()

        // Then
        XCTAssertFalse(soundPlayer.playedEffects.contains(.bip))
        XCTAssertEqual(laneCuePlayer.tickCalls, 0)
        XCTAssertEqual(laneCuePlayer.moveCalls, 1)
    }

    func testGivenCueArpeggioModeWhenPlayingMoveFeedbackThenMoveCueUsesSelectedModeAndLaneStyle() {
        // Given
        scene.setAudioFeedbackMode(.cueArpeggio)
        scene.setLaneMoveCueStyle(.laneConfirmationAndSafety)
        scene.gridState.grid = [
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Car],
            [.Empty, .Player, .Empty]
        ]

        // When
        scene.playFeedback(event: .move(destinationColumn: 2))

        // Then
        XCTAssertEqual(laneCuePlayer.moveCalls, 1)
        XCTAssertEqual(laneCuePlayer.lastMode, .cueArpeggio)
        XCTAssertEqual(laneCuePlayer.lastMoveColumn, .right)
        XCTAssertFalse(laneCuePlayer.lastMoveSafeState)
        XCTAssertEqual(laneCuePlayer.lastMoveCueStyle, .laneConfirmationAndSafety)
    }

    func testGivenSafetyOnlyMoveCueStyleWhenHandlingMoveThenLaneCuePlayerReceivesSafetyOnlyStyle() {
        // Given
        scene.setAudioFeedbackMode(.cueLanePulses)
        scene.setLaneMoveCueStyle(.safetyOnly)
        let adapter = TouchGameInputAdapter(controller: scene, hapticController: haptics)

        // When
        adapter.handleRight()

        // Then
        XCTAssertEqual(laneCuePlayer.moveCalls, 1)
        XCTAssertEqual(laneCuePlayer.lastMoveCueStyle, .safetyOnly)
    }

    func testGivenCueModeWithHapticsStyleWhenMovingToSafeLaneThenSuccessHapticPlaysWithoutMoveCueAudio() {
        // Given
        scene.unpauseGameplay()
        scene.setAudioFeedbackMode(.cueLanePulses)
        scene.setLaneMoveCueStyle(.haptics)
        scene.gridState.grid = [
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Car, .Car, .Empty],
            [.Empty, .Player, .Empty]
        ]
        scene.lastPlayerColumn = 1
        let adapter = TouchGameInputAdapter(controller: scene, hapticController: haptics)

        // When
        adapter.handleRight()

        // Then
        XCTAssertEqual(haptics.successes, 1)
        XCTAssertEqual(haptics.moves, 0)
        XCTAssertEqual(laneCuePlayer.moveCalls, 0)
    }

    func testGivenCueModeWithHapticsStyleWhenRemoteMovingToSafeLaneThenSuccessHapticPlaysWithoutMoveCueAudio() {
        // Given
        scene.unpauseGameplay()
        scene.setAudioFeedbackMode(.cueLanePulses)
        scene.setLaneMoveCueStyle(.haptics)
        scene.gridState.grid = [
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Car, .Car, .Empty],
            [.Empty, .Player, .Empty]
        ]
        scene.lastPlayerColumn = 1
        let adapter = RemoteGameInputAdapter(controller: scene, hapticController: haptics)

        // When
        adapter.handleRight()

        // Then
        XCTAssertEqual(haptics.successes, 1)
        XCTAssertEqual(haptics.moves, 0)
        XCTAssertEqual(laneCuePlayer.moveCalls, 0)
    }

    func testGivenCueModeWithHapticsStyleWhenCrownMovingToSafeLaneThenSuccessHapticPlaysWithoutMoveCueAudio() {
        // Given
        scene.unpauseGameplay()
        scene.setAudioFeedbackMode(.cueLanePulses)
        scene.setLaneMoveCueStyle(.haptics)
        scene.gridState.grid = [
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Car, .Car, .Empty],
            [.Empty, .Player, .Empty]
        ]
        scene.lastPlayerColumn = 1
        let adapter = CrownGameInputAdapter(controller: scene, hapticController: haptics)

        // When
        adapter.handleRight()

        // Then
        XCTAssertEqual(haptics.successes, 1)
        XCTAssertEqual(haptics.moves, 0)
        XCTAssertEqual(laneCuePlayer.moveCalls, 0)
    }

    func testGivenCueModeWithHapticsStyleWhenMovingToUnsafeLaneThenMoveHapticPlaysWithoutMoveCueAudio() {
        // Given
        scene.unpauseGameplay()
        scene.setAudioFeedbackMode(.cueLanePulses)
        scene.setLaneMoveCueStyle(.haptics)
        scene.gridState.grid = [
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Car],
            [.Empty, .Player, .Empty]
        ]
        scene.lastPlayerColumn = 1
        let adapter = TouchGameInputAdapter(controller: scene, hapticController: haptics)

        // When
        adapter.handleRight()

        // Then
        XCTAssertEqual(haptics.successes, 0)
        XCTAssertEqual(haptics.moves, 1)
        XCTAssertEqual(laneCuePlayer.moveCalls, 0)
    }

    func testGivenCollisionWhenHandlingCrashThenFailSoundAndCrashHapticAreTriggered() {
        // Given

        // When
        scene.handleCrash()

        // Then
        XCTAssertTrue(soundPlayer.playedEffects.contains(.fail))
        XCTAssertEqual(haptics.crashes, 1)
        XCTAssertTrue(scene.gameState.isPaused)
    }

    func testGivenCueModeWhenHandlingCrashThenFailSoundMappingStaysUnchanged() {
        // Given
        scene.setAudioFeedbackMode(.cueChord)
        let baselineTickCalls = laneCuePlayer.tickCalls
        let baselineMoveCalls = laneCuePlayer.moveCalls

        // When
        scene.handleCrash()

        // Then
        XCTAssertEqual(soundPlayer.playedEffects.last, .fail)
        XCTAssertEqual(haptics.crashes, 1)
        XCTAssertEqual(laneCuePlayer.tickCalls, baselineTickCalls)
        XCTAssertEqual(laneCuePlayer.moveCalls, baselineMoveCalls)
    }

    func testGivenSceneWhenPlayingSpeedWarningSoundThenDedicatedLaneCueIsUsed() {
        // Given
        let baselineEffects = soundPlayer.playedEffects

        // When
        scene.playSpeedIncreaseWarningSound()

        // Then
        XCTAssertEqual(laneCuePlayer.speedWarningCueCalls, 1)
        XCTAssertEqual(laneCuePlayer.tickCalls, 0)
        XCTAssertEqual(soundPlayer.playedEffects, baselineEffects)
    }

    func testGivenSceneReadyWhenApplyingStartPulseThenPulseMethodsAreCallable() {
        // Given
        scene.start()
        scene.update(1.0) // Ensure sprites are created
        
        // When - verify methods can be called without crashing
        scene.applyStartPulseToPlayerCar()
        
        // Then - verify stop method can be called without crashing
        scene.stopStartPulseOnPlayerCar()
        
        // No crash means the methods work correctly
        XCTAssertTrue(true, "Pulse methods are callable")
    }

    func testGivenCrashSpriteVisibleWhenResumingThenCrashSpriteIsClearedWhileStartSoundPlays() {
        // Given
        var crashGrid = scene.gridState
        let crashRow = crashGrid.playerRowIndex
        crashGrid.grid[crashRow] = [.Empty, .Crash, .Empty]
        scene.gridState = crashGrid
        scene.gridStateDidUpdate(crashGrid, shouldPlayFeedback: false, notifyDelegate: false)
        XCTAssertTrue(scene.spritesForGivenState.contains(where: { $0.name == "crash" }))
        soundPlayer.shouldCallCompletion = false

        // When
        scene.resume()

        // Then
        XCTAssertFalse(scene.spritesForGivenState.contains(where: { $0.name == "crash" }))
        XCTAssertEqual(scene.spritesForGivenState.count, 1)
        XCTAssertTrue(scene.gameState.isPaused)
    }

    func testGivenPendingFailCompletionWhenCompletingFailSoundThenCollisionCallbackFires() {
        // Given
        let nonCompletingPlayer = MockSoundEffectPlayer()
        nonCompletingPlayer.shouldCallCompletion = false
        let nonCompletingLaneCuePlayer = MockLaneCuePlayer()
        let fallbackHaptics = MockHapticFeedbackController()
        let loader = PlatformFactories.makeImageLoader()
        let testScene = GameScene.scene(
            size: CGSize(width: 200, height: 200),
            difficulty: .rapid,
            theme: nil,
            imageLoader: loader,
            soundPlayer: nonCompletingPlayer,
            laneCuePlayer: nonCompletingLaneCuePlayer,
            hapticController: fallbackHaptics,
            audioFeedbackMode: .retro
        )
        let fallbackDelegate = MockGameSceneDelegate(haptics: fallbackHaptics)
        testScene.gameDelegate = fallbackDelegate
        let testView = SKView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
        testView.presentScene(testScene)

        // When
        testScene.handleCrash()
        XCTAssertEqual(fallbackDelegate.crashes, 0)
        let didComplete = nonCompletingPlayer.completePending(for: .fail)

        // Then
        XCTAssertTrue(didComplete)
        XCTAssertEqual(fallbackDelegate.crashes, 1)
    }

    func testGivenRunningSceneWhenGridTicksThenMoveHapticIsNotTriggered() {
        // Given

        // When
        scene.update(1.0) // dt > initial threshold

        // Then
        XCTAssertFalse(soundPlayer.playedEffects.contains(.bip))
        XCTAssertEqual(laneCuePlayer.tickCalls, 1)
        XCTAssertEqual(haptics.gridUpdates, 1)
        XCTAssertEqual(haptics.moves, 0)
    }

    func testGivenImminentSpeedIncreaseWhenUpdatingThenExistingCarsAreNotRemoved() {
        // Given
        scene.unpauseGameplay()
        scene.speedAlertWindowPoints = 99
        scene.gridState.grid = [
            [.Car, .Empty, .Car],
            [.Car, .Car, .Car],
            [.Car, .Car, .Car],
            [.Car, .Empty, .Car],
            [.Empty, .Player, .Empty],
        ]

        // When
        scene.update(1.0)

        // Then
        XCTAssertEqual(scene.gridState.grid[3][1], .Car)
        XCTAssertEqual(scene.gridState.grid[2][1], .Car)
    }

    func testGivenStartOrResumeWhenStartSoundCompletesThenSceneUnpauses() async {
        // Given
        let initialUnpaused = await waitUntilUnpaused(scene)
        XCTAssertTrue(initialUnpaused, "start() should unpause after sound completion")
        scene.pauseGameplay()

        // When
        scene.resume()
        let resumedUnpaused = await waitUntilUnpaused(scene)

        // Then
        XCTAssertTrue(resumedUnpaused, "resume() should unpause after start sound completion")
    }

    func testGivenSceneWithCrashStateWhenResizingThenScoreAndLivesArePreserved() {
        // Given
        scene.handleCrash()
        let initialScore = scene.gameState.score
        let initialLives = scene.gameState.lives

        // When
        scene.resizeScene(to: CGSize(width: 300, height: 300))

        // Then
        XCTAssertEqual(scene.gameState.score, initialScore, "resize should not reset score")
        XCTAssertEqual(scene.gameState.lives, initialLives, "resize should not reset lives")
        XCTAssertEqual(scene.size, CGSize(width: 300, height: 300))
    }

    func testGivenBigCarsDisabledWhenRenderingRivalThenRivalUsesPerspectiveScale() {
        // Given
        scene.setBigRivalCarsEnabled(false)
        scene.gridState.grid = [
            [.Car, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Player, .Empty]
        ]

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)
        let rivalSize = spriteSize(column: 0, row: 0)
        let playerSize = spriteSize(column: 1, row: 4)

        // Then
        guard let rivalSize, let playerSize else {
            XCTFail("Expected rival and player sprites to be rendered")
            return
        }
        XCTAssertLessThan(rivalSize.width, playerSize.width)
    }

    func testGivenBigCarsEnabledWhenRenderingRivalThenRivalMatchesPlayerScale() {
        // Given
        scene.setBigRivalCarsEnabled(true)
        scene.gridState.grid = [
            [.Car, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Player, .Empty]
        ]

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)
        let rivalSize = spriteSize(column: 0, row: 0)
        let playerSize = spriteSize(column: 1, row: 4)

        // Then
        guard let rivalSize, let playerSize else {
            XCTFail("Expected rival and player sprites to be rendered")
            return
        }
        XCTAssertGreaterThanOrEqual(rivalSize.width, playerSize.width)
    }

    func testGivenRoadDashPhaseWhenTickAdvancesThenEmptyRowCyclesEveryFiveTicks() {
        // Given
        scene.unpauseGameplay()
        var emptyRows: [Int] = []

        // When
        for tick in 1...5 {
            scene.update(TimeInterval(tick))
            emptyRows.append(scene.roadDashEmptyRowIndex)
        }

        // Then
        XCTAssertEqual(emptyRows, [0, 1, 2, 3, 4])
    }

    func testGivenLaneMoveWhenRenderingThenRoadDashPhaseDoesNotChange() {
        // Given
        scene.unpauseGameplay()
        scene.update(1.0)
        let baselinePhase = scene.roadDashPhase
        let adapter = TouchGameInputAdapter(controller: scene, hapticController: haptics)

        // When
        adapter.handleLeft()

        // Then
        XCTAssertEqual(scene.roadDashPhase, baselinePhase)
    }

    func testGivenBigCarsDisabledWhenRenderingThenDashedRoadLinesAreVisibleAndVerticalSeparatorsAreHidden() {
        // Given
        scene.setBigRivalCarsEnabled(false)
        scene.setRoadVisualStyle(.detailedRoad)

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)

        // Then
        XCTAssertGreaterThan(lineOverlayCount(named: "road_dash_line"), 0)
        XCTAssertEqual(lineOverlayCount(named: "vertical_grid_line"), 0)
    }

    func testGivenBigCarsEnabledWhenRenderingThenDashedRoadLinesAreHiddenAndVerticalSeparatorsAreVisible() {
        // Given
        scene.setBigRivalCarsEnabled(true)
        scene.setRoadVisualStyle(.detailedRoad)

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)

        // Then
        XCTAssertEqual(lineOverlayCount(named: "road_dash_line"), 0)
        XCTAssertEqual(lineOverlayCount(named: "vertical_grid_line"), 2)
    }

    func testGivenBigCarsEnabledWhenRenderingThenHorizontalGridLinesAreNotDrawn() {
        // Given
        scene.setBigRivalCarsEnabled(true)
        scene.setRoadVisualStyle(.detailedRoad)

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)

        // Then
        XCTAssertTrue(allGridCells().allSatisfy { $0.lineWidth == 0 })
        XCTAssertEqual(lineOverlayCount(named: "vertical_grid_line"), 2)
    }

    func testGivenDashedRoadLinesWhenComparingTopAndBottomSpacingThenTopRowsAreMoreConverged() {
        // Given
        scene.setBigRivalCarsEnabled(false)
        scene.setRoadVisualStyle(.detailedRoad)
        scene.roadDashPhase = 2

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)

        // Then
        let rowsByY = dashedLineRowsByY()
        guard let bottomRow = rowsByY.first,
              let topRow = rowsByY.last else {
            XCTFail("Expected dashed road lines in at least two rows")
            return
        }
        XCTAssertEqual(bottomRow.count, 4)
        XCTAssertEqual(topRow.count, 4)

        let bottomInnerDistance = bottomRow[2] - bottomRow[1]
        let topInnerDistance = topRow[2] - topRow[1]
        XCTAssertLessThan(topInnerDistance, bottomInnerDistance)
        XCTAssertLessThan(bottomInnerDistance, scene.sizeForCell().width)

        let bottomOuterDistance = bottomRow[3] - bottomRow[0]
        let topOuterDistance = topRow[3] - topRow[0]
        XCTAssertLessThan(topOuterDistance, bottomOuterDistance)
    }

    func testGivenDashedRoadLinesWhenComparingInclinationThenOuterLinesConvergeMoreThanInnerLines() {
        // Given
        scene.setBigRivalCarsEnabled(false)
        scene.setRoadVisualStyle(.detailedRoad)
        scene.roadDashPhase = 2

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)

        // Then
        let rowsByY = dashedLineRowsByY()
        guard let bottomRow = rowsByY.first,
              let topRow = rowsByY.last else {
            XCTFail("Expected dashed road lines in at least two rows")
            return
        }

        let leftOuterDrift = abs(bottomRow[0] - topRow[0])
        let leftInnerDrift = abs(bottomRow[1] - topRow[1])
        XCTAssertGreaterThan(leftOuterDrift, leftInnerDrift)

        let rightOuterDrift = abs(bottomRow[3] - topRow[3])
        let rightInnerDrift = abs(bottomRow[2] - topRow[2])
        XCTAssertGreaterThan(rightOuterDrift, rightInnerDrift)
    }

    func testGivenBigCarsOffWhenRoadStyleSimplifiedWhenRenderingThenVerticalSeparatorsVisibleAndDetailedMarkersHidden() {
        // Given
        scene.setBigRivalCarsEnabled(false)
        scene.setRoadVisualStyle(.simplifiedGrid)
        scene.safetyMarkerRows = [1, 3]

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)

        // Then
        XCTAssertEqual(lineOverlayCount(named: "vertical_grid_line"), 2)
        XCTAssertEqual(lineOverlayCount(named: "road_dash_line"), 0)
        XCTAssertEqual(lineOverlayCount(named: "lap_marker_line"), 0)
    }

    func testGivenBigCarsOnWhenRoadStyleDetailedWhenRenderingThenVerticalOnlyModeOverridesDetailedMarkers() {
        // Given
        scene.setBigRivalCarsEnabled(true)
        scene.setRoadVisualStyle(.detailedRoad)
        scene.safetyMarkerRows = [1, 3]

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)

        // Then
        XCTAssertEqual(lineOverlayCount(named: "vertical_grid_line"), 2)
        XCTAssertEqual(lineOverlayCount(named: "road_dash_line"), 0)
        XCTAssertEqual(lineOverlayCount(named: "lap_marker_line"), 0)
    }

    func testGivenDetailedRoadSafetyWindowWhenRenderingThenLapMarkersAppearOnSingleRow() {
        // Given
        scene.setBigRivalCarsEnabled(false)
        scene.setRoadVisualStyle(.detailedRoad)
        scene.safetyMarkerRows = [1, 3]

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)

        // Then
        XCTAssertEqual(lineOverlayCount(named: "lap_marker_line"), 1)
        let rowsByY = lapMarkerRowsByY()
        XCTAssertEqual(rowsByY.count, 1)
        XCTAssertEqual(rowsByY.first?.count, 1)
    }

    func testGivenDetailedRoadSafetyWindowWhenRenderingThenLapOutlineIsBakedInAssetWithoutSeparateOverlayNode() {
        // Given
        scene.setBigRivalCarsEnabled(false)
        scene.setRoadVisualStyle(.detailedRoad)
        scene.safetyMarkerRows = [1, 3]

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)

        // Then
        XCTAssertEqual(lineOverlayCount(named: "lap_marker_outline"), 0)
    }

    func testGivenDetailedRoadSafetyWindowWhenRenderingThenDashedRowsDoNotOverlapLapRows() {
        // Given
        scene.setBigRivalCarsEnabled(false)
        scene.setRoadVisualStyle(.detailedRoad)
        scene.safetyMarkerRows = [1, 3]

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)

        // Then
        let dashedRowY = Set(scene.lineOverlayNodes.compactMap { node -> Int? in
            guard node.name == "road_dash_line" else { return nil }
            return Int(node.position.y.rounded())
        })
        let lapRowY = Set(scene.lineOverlayNodes.compactMap { node -> Int? in
            guard node.name == "lap_marker_line" else { return nil }
            return Int(node.position.y.rounded())
        })
        XCTAssertTrue(dashedRowY.isDisjoint(with: lapRowY))
    }

    func testGivenDetailedRoadSafetyWindowWhenRenderingThenLapMarkersAreNotVerticallyMirrored() {
        // Given
        scene.setBigRivalCarsEnabled(false)
        scene.setRoadVisualStyle(.detailedRoad)
        scene.safetyMarkerRows = [1, 3]

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)

        // Then
        let lapMarkers = scene.lineOverlayNodes.compactMap { node -> SKSpriteNode? in
            guard node.name == "lap_marker_line" else { return nil }
            return node as? SKSpriteNode
        }
        XCTAssertEqual(lapMarkers.count, 1)
        XCTAssertTrue(lapMarkers.allSatisfy { $0.yScale > 0 })
    }

    func testGivenDetailedRoadSafetyWindowWhenRenderingThenLapMarkerSpansRoadInterior() {
        // Given
        scene.setBigRivalCarsEnabled(false)
        scene.setRoadVisualStyle(.detailedRoad)
        scene.safetyMarkerRows = [1, 3]

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)

        // Then
        let lapMarkers = scene.lineOverlayNodes.compactMap { node -> SKSpriteNode? in
            guard node.name == "lap_marker_line" else { return nil }
            return node as? SKSpriteNode
        }
        guard let lapMarker = lapMarkers.first else {
            XCTFail("Expected one lap marker strip")
            return
        }
        let expectedBoundsRow1 = expectedLapInteriorBounds(forRow: 1)
        let expectedBoundsRow3 = expectedLapInteriorBounds(forRow: 3)
        let expectedMinX = (expectedBoundsRow1.lowerBound + expectedBoundsRow3.lowerBound) / 2
        let expectedMaxX = (expectedBoundsRow1.upperBound + expectedBoundsRow3.upperBound) / 2
        XCTAssertEqual(lapMarker.frame.minX, expectedMinX, accuracy: 1.25)
        XCTAssertEqual(lapMarker.frame.maxX, expectedMaxX, accuracy: 1.25)
    }

    func testGivenDetailedRoadSafetyWindowWhenRenderingThenLapMarkerIsCenteredBetweenSafetyRows() {
        // Given
        scene.setBigRivalCarsEnabled(false)
        scene.setRoadVisualStyle(.detailedRoad)
        scene.safetyMarkerRows = [0, 1]

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)

        // Then
        let lapMarkers = scene.lineOverlayNodes.compactMap { node -> SKSpriteNode? in
            guard node.name == "lap_marker_line" else { return nil }
            return node as? SKSpriteNode
        }
        guard lapMarkers.count == 1 else {
            XCTFail("Expected lap marker rows")
            return
        }
        let expectedY = (scene.gridCell(column: 1, row: 0).frame.minY + scene.gridCell(column: 1, row: 1).frame.maxY) / 2
        XCTAssertTrue(lapMarkers.allSatisfy { abs($0.position.y - expectedY) < 0.75 })
    }

    func testGivenDetailedRoadSafetyWindowWhenRenderingThenLapMarkerHeightScalesWithSafetyRowDepth() {
        // Given
        scene.setBigRivalCarsEnabled(false)
        scene.setRoadVisualStyle(.detailedRoad)
        scene.safetyMarkerRows = [1, 3]

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)

        // Then
        let lapMarkers = scene.lineOverlayNodes.compactMap { node -> SKSpriteNode? in
            guard node.name == "lap_marker_line" else { return nil }
            return node as? SKSpriteNode
        }
        guard let lapMarker = lapMarkers.first else {
            XCTFail("Expected one lap marker strip")
            return
        }
        let expectedHeight = expectedLapHeight(topRow: 1, bottomRow: 3)
        XCTAssertEqual(lapMarker.frame.height, expectedHeight, accuracy: 0.75)
    }

    func testGivenDetailedRoadSafetyWindowWhenRowsAreHigherThenLapMarkerHeightIsSmaller() {
        // Given
        scene.setBigRivalCarsEnabled(false)
        scene.setRoadVisualStyle(.detailedRoad)

        // When
        scene.safetyMarkerRows = [0, 1]
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)
        let topHeight = lapMarkerRowsByY().first?.first?.frame.height

        scene.safetyMarkerRows = [2, 3]
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)
        let lowerHeight = lapMarkerRowsByY().first?.first?.frame.height

        // Then
        guard let topHeight, let lowerHeight else {
            XCTFail("Expected lap marker strip in both renders")
            return
        }
        XCTAssertLessThan(topHeight, lowerHeight)
    }

    func testGivenRivalCarsOnSideLanesWhenRenderingThenTopRowRivalsAreCloserToCenterThanLowerRows() {
        // Given
        scene.setBigRivalCarsEnabled(false)
        scene.gridState.grid = [
            [.Car, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Car, .Empty, .Empty],
            [.Empty, .Player, .Empty]
        ]

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)
        let centerX = scene.size.width / 2
        let topRivalX = spriteSceneX(column: 0, row: 0)
        let lowerRivalX = spriteSceneX(column: 0, row: 3)

        // Then
        guard let topRivalX, let lowerRivalX else {
            XCTFail("Expected rival sprites in both rows")
            return
        }
        XCTAssertLessThan(abs(topRivalX - centerX), abs(lowerRivalX - centerX))
    }

    func testGivenPlayerCarOnSideLaneWhenRenderingThenNoAdditionalConvergenceIsApplied() {
        // Given
        scene.setBigRivalCarsEnabled(false)
        scene.gridState.grid = [
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Empty, .Empty, .Empty],
            [.Player, .Empty, .Empty]
        ]

        // When
        scene.gridStateDidUpdate(scene.gridState, shouldPlayFeedback: false, notifyDelegate: false)
        let playerX = spriteSceneX(column: 0, row: 4)
        let expectedX = scene.gridCell(column: 0, row: 4).frame.midX

        // Then
        guard let playerX else {
            XCTFail("Expected player sprite in left lane")
            return
        }
        XCTAssertEqual(playerX, expectedX, accuracy: 0.01)
    }

    func testGivenRunningSceneWhenPausingGameplayThenDelegateReceivesPausedState() {
        // Given

        // When
        scene.pauseGameplay()

        // Then
        XCTAssertTrue(scene.gameState.isPaused)
        XCTAssertEqual(delegate.pauseUpdates.last, true)
    }

    func testGivenPausedSceneWhenUnpausingGameplayThenDelegateReceivesUnpausedState() {
        // Given
        scene.pauseGameplay()

        // When
        scene.unpauseGameplay()

        // Then
        XCTAssertFalse(scene.gameState.isPaused)
        XCTAssertEqual(delegate.pauseUpdates.last, false)
    }

    func testGivenSceneWhenStoppingAllSoundsThenSoundPlayerReceivesFadeDuration() {
        // Given

        // When
        scene.stopAllSounds(fadeDuration: 0.2)

        // Then
        XCTAssertEqual(soundPlayer.stopAllCalls.last, 0.2)
        XCTAssertEqual(laneCuePlayer.stopAllCalls.last, 0.2)
    }

    func testGivenSceneWhenSettingSoundVolumeThenBothAudioPlayersReceiveVolume() {
        // Given

        // When
        scene.setSoundVolume(0.35)

        // Then
        XCTAssertEqual(soundPlayer.lastVolume, 0.35)
        XCTAssertEqual(laneCuePlayer.lastVolume, 0.35)
    }

    func testGivenCrashFlowWhenFailCompletionAndFallbackBothExistThenCollisionCallbackFiresOnce() async {
        // Given
        scene.crashResolutionFallbackDuration = 0.05

        // When
        scene.handleCrash()
        try? await Task.sleep(for: .milliseconds(120))

        // Then
        XCTAssertEqual(delegate.crashes, 1)
    }

    func testGivenMissingStartCompletionWhenFallbackExpiresThenSceneUnpauses() async {
        // Given
        let nonCompletingPlayer = MockSoundEffectPlayer()
        nonCompletingPlayer.shouldCallCompletion = false
        let nonCompletingLaneCuePlayer = MockLaneCuePlayer()
        let loader = PlatformFactories.makeImageLoader()
        let testScene = GameScene.scene(
            size: CGSize(width: 200, height: 200),
            difficulty: .rapid,
            theme: nil,
            imageLoader: loader,
            soundPlayer: nonCompletingPlayer,
            laneCuePlayer: nonCompletingLaneCuePlayer,
            hapticController: nil,
            audioFeedbackMode: .retro
        )
        testScene.startPlaybackFallbackDuration = 0.05
        let testView = SKView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))

        // When
        testView.presentScene(testScene)
        try? await Task.sleep(for: .milliseconds(120))

        // Then
        XCTAssertFalse(testScene.gameState.isPaused)
    }

    func testGivenExternalPauseWhenStartCompletionArrivesThenSceneRemainsPaused() {
        // Given
        let delayedPlayer = MockSoundEffectPlayer()
        delayedPlayer.shouldCallCompletion = false
        let delayedLaneCuePlayer = MockLaneCuePlayer()
        let loader = PlatformFactories.makeImageLoader()
        let testScene = GameScene.scene(
            size: CGSize(width: 200, height: 200),
            difficulty: .rapid,
            theme: nil,
            imageLoader: loader,
            soundPlayer: delayedPlayer,
            laneCuePlayer: delayedLaneCuePlayer,
            hapticController: nil,
            audioFeedbackMode: .retro
        )
        let testView = SKView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))
        testView.presentScene(testScene)
        testScene.setOverlayPauseLock(true)
        testScene.pauseGameplay()

        // When
        let didComplete = delayedPlayer.completePending(for: .start)

        // Then
        XCTAssertTrue(didComplete)
        XCTAssertTrue(testScene.gameState.isPaused)
    }

    func testGivenMissingCrashCompletionWhenFallbackExpiresThenCollisionCallbackIsNotified() async {
        // Given
        let nonCompletingPlayer = MockSoundEffectPlayer()
        nonCompletingPlayer.shouldCallCompletion = false
        let nonCompletingLaneCuePlayer = MockLaneCuePlayer()
        let fallbackHaptics = MockHapticFeedbackController()
        let loader = PlatformFactories.makeImageLoader()
        let testScene = GameScene.scene(
            size: CGSize(width: 200, height: 200),
            difficulty: .rapid,
            theme: nil,
            imageLoader: loader,
            soundPlayer: nonCompletingPlayer,
            laneCuePlayer: nonCompletingLaneCuePlayer,
            hapticController: fallbackHaptics,
            audioFeedbackMode: .retro
        )
        testScene.startPlaybackFallbackDuration = 0.01
        testScene.crashResolutionFallbackDuration = 0.05
        let fallbackDelegate = MockGameSceneDelegate(haptics: fallbackHaptics)
        testScene.gameDelegate = fallbackDelegate
        let testView = SKView(frame: CGRect(origin: .zero, size: CGSize(width: 200, height: 200)))

        // When
        testView.presentScene(testScene)
        try? await Task.sleep(for: .milliseconds(30))
        testScene.handleCrash()
        try? await Task.sleep(for: .milliseconds(120))

        // Then
        XCTAssertEqual(fallbackDelegate.crashes, 1)
    }

    private func waitUntilUnpaused(_ scene: GameScene, timeout: Duration = .milliseconds(500)) async -> Bool {
        let start = ContinuousClock.now
        while ContinuousClock.now - start < timeout {
            if scene.gameState.isPaused == false {
                return true
            }
            try? await Task.sleep(for: .milliseconds(10))
        }
        return scene.gameState.isPaused == false
    }

    private func spriteSize(column: Int, row: Int) -> CGSize? {
        let cell = scene.gridCell(column: column, row: row)
        return cell.children.compactMap { $0 as? SKSpriteNode }.first?.frame.size
    }

    private func lineOverlayCount(named name: String) -> Int {
        scene.lineOverlayNodes.filter { $0.name == name }.count
    }

    private func allGridCells() -> [SKShapeNode] {
        var cells: [SKShapeNode] = []
        for row in 0..<scene.gridState.numberOfRows {
            for column in 0..<scene.gridState.numberOfColumns {
                cells.append(scene.gridCell(column: column, row: row))
            }
        }
        return cells
    }

    private func dashedLineRowsByY() -> [[CGFloat]] {
        let dashedLines = scene.lineOverlayNodes.compactMap { node -> CGPoint? in
            guard node.name == "road_dash_line" else { return nil }
            return node.position
        }
        var grouped: [Int: [CGFloat]] = [:]
        for point in dashedLines {
            grouped[Int(point.y.rounded()), default: []].append(point.x)
        }
        return grouped.keys.sorted().compactMap { key in
            grouped[key]?.sorted()
        }
    }

    private func lapMarkerRowsByY() -> [[SKSpriteNode]] {
        let lapMarkers = scene.lineOverlayNodes.compactMap { node -> SKSpriteNode? in
            guard node.name == "lap_marker_line" else { return nil }
            return node as? SKSpriteNode
        }
        var grouped: [Int: [SKSpriteNode]] = [:]
        for marker in lapMarkers {
            grouped[Int(marker.position.y.rounded()), default: []].append(marker)
        }
        return grouped.keys.sorted().compactMap { key in
            grouped[key]?.sorted(by: { $0.position.x < $1.position.x })
        }
    }

    private func spriteSceneX(column: Int, row: Int) -> CGFloat? {
        let cell = scene.gridCell(column: column, row: row)
        guard let sprite = cell.children.compactMap({ $0 as? SKSpriteNode }).first else {
            return nil
        }
        return cell.convert(sprite.position, to: scene).x
    }

    private func expectedLapInteriorBounds(forRow row: Int) -> ClosedRange<CGFloat> {
        let cellSize = scene.sizeForCell()
        let sizeFactor = CGFloat(row + 1) / CGFloat(scene.gridState.numberOfRows)
        let dashWidth = cellSize.width * sizeFactor
        let inset = max(1, dashWidth * 0.03)

        let leftCell = scene.gridCell(column: 0, row: row)
        let rightCell = scene.gridCell(column: 2, row: row)
        let leftDashMinX = leftCell.frame.maxX - dashWidth
        let rightDashMaxX = rightCell.frame.minX + dashWidth
        let leftInteriorX = leftDashMinX + (dashWidth * 0.195) + inset
        let rightInteriorX = rightDashMaxX - (dashWidth * 0.195) - inset
        return leftInteriorX...rightInteriorX
    }

    private func expectedLapHeight(topRow: Int, bottomRow: Int) -> CGFloat {
        let averageRow = (CGFloat(topRow) + CGFloat(bottomRow)) / 2
        let perspectiveFactor = (averageRow + 1) / CGFloat(scene.gridState.numberOfRows)
        return scene.sizeForCell().height * 0.42 * perspectiveFactor
    }
}

// MARK: - Mocks

final class MockSoundEffectPlayer: SoundEffectPlayer {
    private(set) var playedEffects: [SoundEffect] = []
    private(set) var stopAllCalls: [TimeInterval] = []
    private(set) var lastVolume: Double?
    private var pendingCompletions: [SoundEffect: [() -> Void]] = [:]
    var shouldCallCompletion = true

    func play(_ effect: SoundEffect, completion: (() -> Void)?) {
        playedEffects.append(effect)
        if shouldCallCompletion {
            completion?()
        } else if let completion {
            pendingCompletions[effect, default: []].append(completion)
        }
    }

    func stopAll(fadeDuration: TimeInterval) {
        stopAllCalls.append(fadeDuration)
    }

    func setVolume(_ volume: Double) {
        lastVolume = volume
    }

    @discardableResult
    func completePending(for effect: SoundEffect) -> Bool {
        guard var completions = pendingCompletions[effect], completions.isEmpty == false else {
            return false
        }
        let completion = completions.removeFirst()
        pendingCompletions[effect] = completions
        completion()
        return true
    }
}

final class MockLaneCuePlayer: LaneCuePlayer {
    private(set) var tickCalls = 0
    private(set) var moveCalls = 0
    private(set) var speedWarningCueCalls = 0
    private(set) var lastTickSafeColumns: Set<CueColumn> = []
    private(set) var lastMoveColumn: CueColumn?
    private(set) var lastMoveSafeState = true
    private(set) var lastMode: AudioFeedbackMode = .retro
    private(set) var lastMoveCueStyle: LaneMoveCueStyle = .defaultStyle
    private(set) var stopAllCalls: [TimeInterval] = []
    private(set) var lastVolume: Double?

    func playTickCue(safeColumns: Set<CueColumn>, mode: AudioFeedbackMode) {
        tickCalls += 1
        lastTickSafeColumns = safeColumns
        lastMode = mode
    }

    func playMoveCue(column: CueColumn, isSafe: Bool, mode: AudioFeedbackMode, style: LaneMoveCueStyle) {
        moveCalls += 1
        lastMoveColumn = column
        lastMoveSafeState = isSafe
        lastMode = mode
        lastMoveCueStyle = style
    }

    func setVolume(_ volume: Double) {
        lastVolume = volume
    }

    func playSpeedWarningCue() {
        speedWarningCueCalls += 1
    }

    func stopAll(fadeDuration: TimeInterval) {
        stopAllCalls.append(fadeDuration)
    }
}

final class MockGameSceneDelegate: GameSceneDelegate {
    private(set) var scoreUpdates: [Int] = []
    private(set) var crashes = 0
    private(set) var gridUpdatesCount = 0
    private(set) var pauseUpdates: [Bool] = []
    private let haptics: MockHapticFeedbackController

    init(haptics: MockHapticFeedbackController) {
        self.haptics = haptics
    }

    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int) {
        scoreUpdates.append(score)
    }

    func gameSceneDidDetectCollision(_ gameScene: GameScene) {
        crashes += 1
    }

    func gameSceneDidUpdateGrid(_ gameScene: GameScene) {
        gridUpdatesCount += 1
        haptics.triggerGridUpdateHaptic()
    }

    func gameScene(_ gameScene: GameScene, didUpdatePauseState isPaused: Bool) {
        pauseUpdates.append(isPaused)
    }

    func gameScene(_ gameScene: GameScene, didAchieveNewHighScore score: Int) { }
}
