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

    func testMoveTriggersBipAndHaptic() {
        let adapter = TouchGameInputAdapter(controller: scene, hapticController: haptics)
        adapter.handleLeft()

        XCTAssertEqual(soundPlayer.playedEffects, [.start, .bip])
        XCTAssertEqual(delegate.gridUpdatesCount, 0, "Move should not notify grid update delegate")
        XCTAssertEqual(haptics.moves, 1)
        XCTAssertEqual(haptics.gridUpdates, 0)
    }

    func testGridTickTriggersBipAndHaptic() {
        scene.update(1.0) // dt > initial threshold

        XCTAssertTrue(soundPlayer.playedEffects.contains(.bip))
        XCTAssertEqual(delegate.gridUpdatesCount, 1)
        XCTAssertEqual(haptics.gridUpdates, 1)
    }

    func testCrashTriggersFailSoundAndCrashHaptic() {
        scene.handleCrash()

        XCTAssertTrue(soundPlayer.playedEffects.contains(.fail))
        XCTAssertEqual(haptics.crashes, 1)
        XCTAssertTrue(scene.gameState.isPaused)
    }

    func testGridTickTriggersLightHapticOnly() {
        scene.update(1.0) // dt > initial threshold

        XCTAssertTrue(soundPlayer.playedEffects.contains(.bip))
        XCTAssertEqual(haptics.gridUpdates, 1)
        XCTAssertEqual(haptics.moves, 0)
    }

    func testStartAndResumeUnpauseAfterSound() {
        XCTAssertFalse(scene.gameState.isPaused, "start() should unpause after sound completion")
        scene.pauseGameplay()
        scene.resume()
        XCTAssertFalse(scene.gameState.isPaused, "resume() should unpause after start sound completion")
    }

    func testResizeSceneRedrawsWithoutResettingState() {
        scene.handleCrash()
        let initialScore = scene.gameState.score
        let initialLives = scene.gameState.lives

        scene.resizeScene(to: CGSize(width: 300, height: 300))

        XCTAssertEqual(scene.gameState.score, initialScore, "resize should not reset score")
        XCTAssertEqual(scene.gameState.lives, initialLives, "resize should not reset lives")
        XCTAssertEqual(scene.size, CGSize(width: 300, height: 300))
    }

    func testPauseGameplayNotifiesDelegate() {
        scene.pauseGameplay()

        XCTAssertTrue(scene.gameState.isPaused)
        XCTAssertEqual(delegate.pauseUpdates.last, true)
    }

    func testUnpauseGameplayNotifiesDelegate() {
        scene.pauseGameplay()
        scene.unpauseGameplay()

        XCTAssertFalse(scene.gameState.isPaused)
        XCTAssertEqual(delegate.pauseUpdates.last, false)
    }

    func testStopAllSoundsIsInvoked() {
        scene.stopAllSounds(fadeDuration: 0.2)
        XCTAssertEqual(soundPlayer.stopAllCalls.last, 0.2)
    }
}

// MARK: - Mocks

final class MockSoundEffectPlayer: SoundEffectPlayer {
    private(set) var playedEffects: [SoundEffect] = []
    private(set) var stopAllCalls: [TimeInterval] = []
    private(set) var lastVolume: Double?

    func play(_ effect: SoundEffect, completion: (() -> Void)?) {
        playedEffects.append(effect)
        completion?()
    }

    func stopAll(fadeDuration: TimeInterval) {
        stopAllCalls.append(fadeDuration)
    }

    func setVolume(_ volume: Double) {
        lastVolume = volume
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
