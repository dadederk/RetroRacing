//
//  GameScene.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import SpriteKit
import SwiftUI
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

/// Input commands for the game. Named to avoid shadowing the GameController framework (physical controllers).
public protocol RacingGameController {
    func moveLeft()
    func moveRight()
}

/// SpriteKit scene that owns shared gameplay flow, grid updates, and sound feedback for RetroRacing.
public class GameScene: SKScene {
    /// Bundle containing all game assets (sprites, sounds). Assets live only in RetroRacingShared; load from here.
    static let sharedBundle = Bundle(for: GameScene.self)

    // Assets (SKColor is UIColor on iOS/tvOS, NSColor on macOS). Internal so GameScene+Grid/Effects can access.
    let gameBackgroundColor = SKColor(red: 202.0 / 255.0, green: 220.0 / 255.0, blue: 159.0 / 255.0, alpha: 1.0)

    /// Injected sound player for all SFX.
    public var soundPlayer: SoundEffectPlayer?
    /// Optional haptic controller to fire crash haptics immediately on collision.
    public var hapticController: HapticFeedbackController?

    private var initialDtForGameUpdate = 0.6
    private var lastGameUpdateTime: TimeInterval = 0
    private var hasConfiguredScene = false
    var lastConfiguredSize: CGSize?

    var spritesForGivenState = [SKSpriteNode]()

    let gridCalculator = GridStateCalculator(randomSource: InfrastructureDefaults.randomSource)
    var gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
    public private(set) var gameState = GameState()
    private var lastPlayerColumn: Int = 1

    /// When set, sprite asset names and grid cell color come from the theme; otherwise LCD defaults.
    public var theme: (any GameTheme)?

    /// Loads sprite images from the bundle. Injected so shared code has no UIKit/AppKit conditionals.
    /// Optional so scene can be created before assignment; e.g. on watchOS sceneDidLoad() may run early.
    public var imageLoader: (any ImageLoader)?

    public weak var gameDelegate: GameSceneDelegate?
    
    private func updatePauseState(_ isPaused: Bool) {
        guard gameState.isPaused != isPaused else { return }
        gameState.isPaused = isPaused
        gameDelegate?.gameScene(self, didUpdatePauseState: isPaused)
    }

    public init(
        size: CGSize,
        theme: (any GameTheme)?,
        imageLoader: any ImageLoader,
        soundPlayer: SoundEffectPlayer,
        hapticController: HapticFeedbackController?
    ) {
        super.init(size: size)
        self.theme = theme
        self.imageLoader = imageLoader
        self.soundPlayer = soundPlayer
        self.hapticController = hapticController
    }

    public override init(size: CGSize) {
        super.init(size: size)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    /// Creates a new game scene with the given size. Use this for SwiftUI SpriteView when no .sks file is used.
    /// Grid is created when the scene is presented (didMove/to view or sceneDidLoad); use view size when possible so scene size matches view and scaling is 1:1.
    /// - Parameters:
    ///   - size: Scene size.
    ///   - theme: Optional theme; when provided, sprite asset names (playerCarSprite, rivalCarSprite, crashSprite) are used.
    ///   - imageLoader: Loader for sprite textures (platform-specific: UIKit vs AppKit).
    public static func scene(
        size: CGSize,
        theme: (any GameTheme)? = nil,
        imageLoader: some ImageLoader,
        soundPlayer: SoundEffectPlayer = PlatformFactories.makeSoundPlayer(),
        hapticController: HapticFeedbackController? = nil
    ) -> GameScene {
        let scene = GameScene(
            size: size,
            theme: theme,
            imageLoader: imageLoader,
            soundPlayer: soundPlayer,
            hapticController: hapticController
        )
        scene.anchorPoint = CGPoint(x: 0, y: 0)
        scene.scaleMode = .aspectFit
        return scene
    }

    /// Creates a new game scene. Use programmatic size; .sks loading uses main bundle and is not used from framework.
    /// Caller must set imageLoader before presenting the scene if using this initializer.
    public class func newGameScene(
        imageLoader: some ImageLoader,
        soundPlayer: SoundEffectPlayer = PlatformFactories.makeSoundPlayer(),
        hapticController: HapticFeedbackController? = nil
    ) -> GameScene {
        let defaultSize = CGSize(width: 800, height: 600)
        return scene(size: defaultSize, theme: nil, imageLoader: imageLoader, soundPlayer: soundPlayer, hapticController: hapticController)
    }

    public func start() {
        initialiseGame()
    }

    /// Pauses gameplay without resetting grid or score. Used by user-facing pause control.
    public func pauseGameplay() {
        updatePauseState(true)
    }

    /// Resumes gameplay after a user pause without resetting the grid.
    public func unpauseGameplay() {
        updatePauseState(false)
    }

    public func resume() {
        gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        updatePauseState(true)
        play(.start) { [weak self] in
            self?.updatePauseState(false)
        }
    }

    func setUpScene() {
        AppLog.log(AppLog.game + AppLog.assets, "setUpScene bundle=\(Self.sharedBundle.bundleURL.path) size=\(size)")

        if hasConfiguredScene {
            resizeScene(to: size)
        } else {
            hasConfiguredScene = true
            lastConfiguredSize = size
            anchorPoint = CGPoint(x: 0, y: 0)
            scaleMode = .aspectFit
            backgroundColor = gameBackgroundColor
            AppLog.log(AppLog.game + AppLog.assets, "setUpScene initial anchorPoint=\(anchorPoint)")
            createGrid()
            initialiseGame()
        }
    }

#if os(watchOS)
    public override func sceneDidLoad() {
        setUpScene()
    }
#else
    public override func didMove(to view: SKView) {
        setUpScene()
    }
#endif

    public override func update(_ currentTime: TimeInterval) {
        guard gameState.isPaused == false else { return }

        let dtGameUpdate = currentTime - lastGameUpdateTime
        let dtForGameUpdate = gridCalculator.intervalForLevel(gameState.level)

        if dtGameUpdate > dtForGameUpdate {
            lastGameUpdateTime = currentTime

            var effects: [GridStateCalculator.Effect]
            (gridState, effects) = gridCalculator.nextGrid(previousGrid: gridState, actions: [.update])

            for effect in effects {
                switch effect {
                case .scored(points: let points):
                    gameState.score += points
                    gameDelegate?.gameScene(self, didUpdateScore: gameState.score)
                case .crashed:
                    ensureCrashSpriteAtLastPlayerColumn()
                    handleCrash()
                }
            }

            gridStateDidUpdate(gridState)
        }
    }

    private func initialiseGame() {
        lastGameUpdateTime = 0
        gridState = GridState(numberOfRows: 5, numberOfColumns: 3)
        lastPlayerColumn = gridState.playerRow().firstIndex(of: .Player) ?? 1
        gameState = GameState()
        gridStateDidUpdate(gridState, shouldPlayFeedback: false, notifyDelegate: false)
        updatePauseState(true)
        play(.start) { [weak self] in
            self?.updatePauseState(false)
        }
    }

    func handleCrash() {
        updatePauseState(true)
        gameState.lives -= 1
        hapticController?.triggerCrashHaptic()
        play(.fail, completion: nil)

        run(SKAction.wait(forDuration: 2.0)) { [weak self] in
            guard let self = self else { return }
            self.gameDelegate?.gameSceneDidDetectCollision(self)
        }
    }

    private func ensureCrashSpriteAtLastPlayerColumn() {
        guard lastPlayerColumn < gridState.numberOfColumns else { return }
        let crashRow = gridState.playerRowIndex
        gridState.grid[crashRow] = Array(repeating: .Empty, count: gridState.numberOfColumns)
        gridState.grid[crashRow][lastPlayerColumn] = .Crash
    }

    func play(_ effect: SoundEffect, completion: (() -> Void)? = nil) {
        guard let soundPlayer else {
            completion?()
            return
        }
        soundPlayer.play(effect, completion: completion)
    }

    public func setSoundVolume(_ volume: Double) {
        soundPlayer?.setVolume(volume)
    }

    public func stopAllSounds(fadeDuration: TimeInterval = 0.15) {
        soundPlayer?.stopAll(fadeDuration: fadeDuration)
    }
}

extension GameScene: RacingGameController {
    public func moveLeft() {
        guard !gameState.isPaused else { return }

        (gridState, _) = gridCalculator.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .left)])
        lastPlayerColumn = gridState.playerRow().firstIndex(of: .Player) ?? lastPlayerColumn

        gridStateDidUpdate(gridState, shouldPlayFeedback: true, notifyDelegate: false)
    }

    public func moveRight() {
        guard !gameState.isPaused else { return }

        (gridState, _) = gridCalculator.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .right)])
        lastPlayerColumn = gridState.playerRow().firstIndex(of: .Player) ?? lastPlayerColumn

        gridStateDidUpdate(gridState, shouldPlayFeedback: true, notifyDelegate: false)
    }
}

// MARK: - Input adapters

public protocol GameInputAdapter {
    func handleLeft()
    func handleRight()
    func handleDrag(translation: CGSize)
}

public struct TouchGameInputAdapter: GameInputAdapter {
    private let controller: RacingGameController
    private let hapticController: HapticFeedbackController?

    public init(controller: RacingGameController, hapticController: HapticFeedbackController?) {
        self.controller = controller
        self.hapticController = hapticController
    }

    public func handleLeft() {
        hapticController?.triggerMoveHaptic()
        controller.moveLeft()
    }

    public func handleRight() {
        hapticController?.triggerMoveHaptic()
        controller.moveRight()
    }

    public func handleDrag(translation: CGSize) {
        guard translation.width != 0 else { return }
        translation.width < 0 ? handleLeft() : handleRight()
    }
}

public struct RemoteGameInputAdapter: GameInputAdapter {
    private let controller: RacingGameController
    private let hapticController: HapticFeedbackController?

    public init(controller: RacingGameController, hapticController: HapticFeedbackController?) {
        self.controller = controller
        self.hapticController = hapticController
    }

    public func handleLeft() {
        hapticController?.triggerMoveHaptic()
        controller.moveLeft()
    }

    public func handleRight() {
        hapticController?.triggerMoveHaptic()
        controller.moveRight()
    }

    public func handleDrag(translation: CGSize) {
        guard translation.width != 0 else { return }
        translation.width < 0 ? handleLeft() : handleRight()
    }
}

public struct CrownGameInputAdapter: GameInputAdapter {
    private let controller: RacingGameController

    public init(controller: RacingGameController) {
        self.controller = controller
    }

    public func handleLeft() {
        controller.moveLeft()
    }

    public func handleRight() {
        controller.moveRight()
    }

    public func handleDrag(translation: CGSize) { }
}
