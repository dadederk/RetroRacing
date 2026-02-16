import XCTest
import SpriteKit
@testable import RetroRacingShared

@MainActor
final class GameSceneAudioHapticsTests: XCTestCase {
    private var soundPlayer: MockSoundEffectPlayer!
    private var haptics: MockHapticFeedbackController!
    private var scene: GameScene!
    private var delegate: MockGameSceneDelegate!
    private var skView: SKView!

    override func setUp() {
        super.setUp()
        soundPlayer = MockSoundEffectPlayer()
        haptics = MockHapticFeedbackController()
        let loader = PlatformFactories.makeImageLoader()
        scene = GameScene.scene(
            size: CGSize(width: 200, height: 200),
            theme: nil,
            imageLoader: loader,
            soundPlayer: soundPlayer,
            hapticController: haptics
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
        soundPlayer = nil
        super.tearDown()
    }

    func testGivenRunningSceneWhenHandlingLeftInputThenBipAndMoveHapticAreTriggered() {
        // Given
        let adapter = TouchGameInputAdapter(controller: scene, hapticController: haptics)

        // When
        adapter.handleLeft()

        // Then
        XCTAssertEqual(soundPlayer.playedEffects, [.start, .bip])
        XCTAssertEqual(delegate.gridUpdatesCount, 0, "Move should not notify grid update delegate")
        XCTAssertEqual(haptics.moves, 1)
        XCTAssertEqual(haptics.gridUpdates, 0)
    }

    func testGivenPausedSceneWhenHandlingLeftInputThenMoveHapticAndSoundAreNotTriggered() {
        // Given
        let adapter = TouchGameInputAdapter(controller: scene, hapticController: haptics)
        scene.pauseGameplay()
        let baselineMoves = haptics.moves
        let baselineEffects = soundPlayer.playedEffects

        // When
        adapter.handleLeft()

        // Then
        XCTAssertEqual(haptics.moves, baselineMoves)
        XCTAssertEqual(soundPlayer.playedEffects, baselineEffects)
    }

    func testGivenRunningSceneWhenUpdatingBeyondThresholdThenGridTickBipAndHapticAreTriggered() {
        // Given

        // When
        scene.update(1.0) // dt > initial threshold

        // Then
        XCTAssertTrue(soundPlayer.playedEffects.contains(.bip))
        XCTAssertEqual(delegate.gridUpdatesCount, 1)
        XCTAssertEqual(haptics.gridUpdates, 1)
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

    func testGivenRunningSceneWhenGridTicksThenMoveHapticIsNotTriggered() {
        // Given

        // When
        scene.update(1.0) // dt > initial threshold

        // Then
        XCTAssertTrue(soundPlayer.playedEffects.contains(.bip))
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
        let loader = PlatformFactories.makeImageLoader()
        let testScene = GameScene.scene(
            size: CGSize(width: 200, height: 200),
            theme: nil,
            imageLoader: loader,
            soundPlayer: nonCompletingPlayer,
            hapticController: nil
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
        let loader = PlatformFactories.makeImageLoader()
        let testScene = GameScene.scene(
            size: CGSize(width: 200, height: 200),
            theme: nil,
            imageLoader: loader,
            soundPlayer: delayedPlayer,
            hapticController: nil
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
        let fallbackHaptics = MockHapticFeedbackController()
        let loader = PlatformFactories.makeImageLoader()
        let testScene = GameScene.scene(
            size: CGSize(width: 200, height: 200),
            theme: nil,
            imageLoader: loader,
            soundPlayer: nonCompletingPlayer,
            hapticController: fallbackHaptics
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
