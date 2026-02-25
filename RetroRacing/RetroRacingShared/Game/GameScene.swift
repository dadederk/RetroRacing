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

// Single source of truth for the game grid dimensions.
private enum GridConfiguration {
    static let numberOfRows = 5
    static let numberOfColumns = 3
}

private enum SpeedIncreaseConfiguration {
    static let preLevelForecastRows = 4
    static let safetyRowOffsetsBeforeLevelChange: Set<Int> = [2, 3]
}

private enum AudioFallbackConfiguration {
    static let startUnpauseSeconds: TimeInterval = 2.0
    // fail.m4a is ~7.42s; keep fallback above clip length for missing-completion edge cases.
    static let crashResolutionSeconds: TimeInterval = 8.0
}

/// Input commands for the game. Named to avoid shadowing the GameController framework (physical controllers).
public protocol RacingGameController {
    func moveLeft()
    func moveRight()
}

enum AudioFeedbackEvent {
    case tick
    case move(destinationColumn: Int)
}

/// SpriteKit scene that owns shared gameplay flow, grid updates, and sound feedback for RetroRacing.
public class GameScene: SKScene {
    /// Bundle containing all game assets (sprites, sounds). Assets live only in RetroRacingShared; load from here.
    static let sharedBundle = Bundle(for: GameScene.self)

    // Assets (SKColor is UIColor on iOS/tvOS, NSColor on macOS). Internal so GameScene+Grid/Effects can access.
    let gameBackgroundColor = SKColor(red: 202.0 / 255.0, green: 220.0 / 255.0, blue: 159.0 / 255.0, alpha: 1.0)

    /// Injected sound player for all SFX.
    public var soundPlayer: SoundEffectPlayer?
    /// Injected lane-cue player for accessibility-driven guidance.
    public var laneCuePlayer: LaneCuePlayer?
    /// Optional haptic controller to fire crash haptics immediately on collision.
    public var hapticController: HapticFeedbackController?
    public private(set) var audioFeedbackMode: AudioFeedbackMode = .defaultMode
    public private(set) var laneMoveCueStyle: LaneMoveCueStyle = .defaultStyle
    public private(set) var bigRivalCarsEnabled = false

    private var initialDtForGameUpdate = 0.6
    private var lastGameUpdateTime: TimeInterval = 0
    private var hasConfiguredScene = false
    var lastConfiguredSize: CGSize?
    private var startUnpauseFallbackTask: Task<Void, Never>?
    private var crashResolutionFallbackTask: Task<Void, Never>?
    private var isWaitingForCrashResolution = false
    private var isOverlayPauseLocked = false

    var spritesForGivenState = [SKSpriteNode]()

    private var gridCalculator = GridStateCalculator(
        randomSource: InfrastructureDefaults.randomSource,
        timingConfiguration: GameDifficulty.defaultDifficulty.timingConfiguration
    )
    var gridState = GridState(
        numberOfRows: GridConfiguration.numberOfRows,
        numberOfColumns: GridConfiguration.numberOfColumns
    )
    public private(set) var gameState = GameState()
    public private(set) var difficulty: GameDifficulty = .defaultDifficulty
    var lastPlayerColumn: Int = 1
    private var lastLevelChangeImminent = false

    /// Number of points before level-up to show the speed-increasing alert; configurable, defaults to 3.
    public var speedAlertWindowPoints: Int = GameState.defaultSpeedAlertWindowPoints

    /// When set, sprite asset names and grid cell color come from the theme; otherwise LCD defaults.
    public var theme: (any GameTheme)?

    /// Loads sprite images from the bundle. Injected so shared code has no UIKit/AppKit conditionals.
    /// Optional so scene can be created before assignment; e.g. on watchOS sceneDidLoad() may run early.
    public var imageLoader: (any ImageLoader)?

    public weak var gameDelegate: GameSceneDelegate?

    /// Fallback used when audio completion does not fire (e.g. route changes); tests can override.
    var startPlaybackFallbackDuration: TimeInterval = AudioFallbackConfiguration.startUnpauseSeconds
    /// Fallback used when crash audio completion does not fire (e.g. route changes); tests can override.
    var crashResolutionFallbackDuration: TimeInterval = AudioFallbackConfiguration.crashResolutionSeconds
    
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
        laneCuePlayer: LaneCuePlayer?,
        hapticController: HapticFeedbackController?,
        audioFeedbackMode: AudioFeedbackMode,
        laneMoveCueStyle: LaneMoveCueStyle,
        difficulty: GameDifficulty,
        bigRivalCarsEnabled: Bool = false
    ) {
        super.init(size: size)
        self.theme = theme
        self.imageLoader = imageLoader
        self.soundPlayer = soundPlayer
        self.laneCuePlayer = laneCuePlayer
        self.hapticController = hapticController
        self.audioFeedbackMode = audioFeedbackMode
        self.laneMoveCueStyle = laneMoveCueStyle
        self.bigRivalCarsEnabled = bigRivalCarsEnabled
        applyDifficulty(difficulty)
    }

    public override init(size: CGSize) {
        super.init(size: size)
        audioFeedbackMode = .defaultMode
        laneMoveCueStyle = .defaultStyle
        applyDifficulty(.defaultDifficulty)
    }

    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        audioFeedbackMode = .defaultMode
        laneMoveCueStyle = .defaultStyle
        applyDifficulty(.defaultDifficulty)
    }

    deinit {
        startUnpauseFallbackTask?.cancel()
        crashResolutionFallbackTask?.cancel()
    }

    /// Creates a new game scene with the given size. Use this for SwiftUI SpriteView when no .sks file is used.
    /// Grid is created when the scene is presented (didMove/to view or sceneDidLoad); use view size when possible so scene size matches view and scaling is 1:1.
    /// - Parameters:
    ///   - size: Scene size.
    ///   - theme: Optional theme; when provided, sprite asset names (playerCarSprite, rivalCarSprite, crashSprite) are used.
    ///   - imageLoader: Loader for sprite textures (platform-specific: UIKit vs AppKit).
    public static func scene(
        size: CGSize,
        difficulty: GameDifficulty,
        theme: (any GameTheme)? = nil,
        imageLoader: some ImageLoader,
        soundPlayer: SoundEffectPlayer = PlatformFactories.makeSoundPlayer(),
        laneCuePlayer: LaneCuePlayer? = nil,
        hapticController: HapticFeedbackController? = nil,
        audioFeedbackMode: AudioFeedbackMode = .defaultMode,
        laneMoveCueStyle: LaneMoveCueStyle = .defaultStyle,
        bigRivalCarsEnabled: Bool = false
    ) -> GameScene {
        let scene = GameScene(
            size: size,
            theme: theme,
            imageLoader: imageLoader,
            soundPlayer: soundPlayer,
            laneCuePlayer: laneCuePlayer,
            hapticController: hapticController,
            audioFeedbackMode: audioFeedbackMode,
            laneMoveCueStyle: laneMoveCueStyle,
            difficulty: difficulty,
            bigRivalCarsEnabled: bigRivalCarsEnabled
        )
        scene.anchorPoint = CGPoint(x: 0, y: 0)
        scene.scaleMode = .aspectFit
        return scene
    }

    /// Creates a new game scene. Use programmatic size; .sks loading uses main bundle and is not used from framework.
    /// Caller must set imageLoader before presenting the scene if using this initializer.
    public class func newGameScene(
        difficulty: GameDifficulty,
        imageLoader: some ImageLoader,
        soundPlayer: SoundEffectPlayer = PlatformFactories.makeSoundPlayer(),
        laneCuePlayer: LaneCuePlayer? = nil,
        hapticController: HapticFeedbackController? = nil,
        audioFeedbackMode: AudioFeedbackMode = .defaultMode,
        laneMoveCueStyle: LaneMoveCueStyle = .defaultStyle,
        bigRivalCarsEnabled: Bool = false
    ) -> GameScene {
        let defaultSize = CGSize(width: 800, height: 600)
        return scene(
            size: defaultSize,
            difficulty: difficulty,
            theme: nil,
            imageLoader: imageLoader,
            soundPlayer: soundPlayer,
            laneCuePlayer: laneCuePlayer,
            hapticController: hapticController,
            audioFeedbackMode: audioFeedbackMode,
            laneMoveCueStyle: laneMoveCueStyle,
            bigRivalCarsEnabled: bigRivalCarsEnabled
        )
    }

    /// Applies a new speed level without resetting score, lives, or grid state.
    public func applyDifficulty(_ difficulty: GameDifficulty) {
        self.difficulty = difficulty
        speedAlertWindowPoints = difficulty.speedAlertWindowPoints
        gridCalculator = GridStateCalculator(
            randomSource: InfrastructureDefaults.randomSource,
            timingConfiguration: difficulty.timingConfiguration
        )
        let isImminent = GameState.isLevelChangeImminent(
            score: gameState.score,
            windowPoints: speedAlertWindowPoints
        )
        if isImminent != lastLevelChangeImminent {
            lastLevelChangeImminent = isImminent
            gameDelegate?.gameScene(self, levelChangeImminent: isImminent)
        }
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

    /// Locks or unlocks pause state while the menu overlay is visible.
    public func setOverlayPauseLock(_ isLocked: Bool) {
        isOverlayPauseLocked = isLocked
    }

    public func resume() {
        cancelCrashResolutionIfNeeded()
        gridState = GridState(
            numberOfRows: GridConfiguration.numberOfRows,
            numberOfColumns: GridConfiguration.numberOfColumns
        )
        lastPlayerColumn = gridState.playerRow().firstIndex(of: .Player) ?? lastPlayerColumn
        gridStateDidUpdate(gridState, shouldPlayFeedback: false, notifyDelegate: false)
        playStartThenUnpause()
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

            let updateAction: GridStateCalculator.Action = shouldInsertSafetyRowBeforeNextLevel() ? .updateWithEmptyRow : .update
            var effects: [GridStateCalculator.Effect]
            (gridState, effects) = gridCalculator.nextGrid(previousGrid: gridState, actions: [updateAction])

            for effect in effects {
                switch effect {
                case .scored(points: let points):
                    gameState.score += points
                    gameDelegate?.gameScene(self, didUpdateScore: gameState.score)
                    let isImminent = GameState.isLevelChangeImminent(score: gameState.score, windowPoints: speedAlertWindowPoints)
                    if isImminent != lastLevelChangeImminent {
                        lastLevelChangeImminent = isImminent
                        gameDelegate?.gameScene(self, levelChangeImminent: isImminent)
                    }
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
        gridState = GridState(
            numberOfRows: GridConfiguration.numberOfRows,
            numberOfColumns: GridConfiguration.numberOfColumns
        )
        lastPlayerColumn = gridState.playerRow().firstIndex(of: .Player) ?? 1
        gameState = GameState()
        if lastLevelChangeImminent {
            lastLevelChangeImminent = false
            gameDelegate?.gameScene(self, levelChangeImminent: false)
        }
        cancelCrashResolutionIfNeeded()
        gridStateDidUpdate(gridState, shouldPlayFeedback: false, notifyDelegate: false)
        playStartThenUnpause()
    }

    func handleCrash() {
        guard isWaitingForCrashResolution == false else { return }
        isWaitingForCrashResolution = true
        startUnpauseFallbackTask?.cancel()
        startUnpauseFallbackTask = nil
        updatePauseState(true)
        gameState.lives -= 1
        hapticController?.triggerCrashHaptic()
        play(.fail) { [weak self] in
            self?.resolveCrashIfNeeded()
        }
        crashResolutionFallbackTask?.cancel()
        crashResolutionFallbackTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.crashResolutionFallbackDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.resolveCrashIfNeeded()
        }
    }

    private func shouldInsertSafetyRowBeforeNextLevel() -> Bool {
        let upcomingRowPoints = (1...SpeedIncreaseConfiguration.preLevelForecastRows).map { rowOffset in
            carsCount(inRow: gridState.playerRowIndex - rowOffset)
        }
        guard let levelChangeOffset = GameState.updatesUntilNextLevelChange(
            score: gameState.score,
            upcomingRowPoints: upcomingRowPoints
        ) else {
            return false
        }
        return SpeedIncreaseConfiguration.safetyRowOffsetsBeforeLevelChange.contains(levelChangeOffset)
    }

    private func carsCount(inRow rowIndex: Int) -> Int {
        guard rowIndex >= 0 && rowIndex < gridState.numberOfRows else { return 0 }
        return gridState.grid[rowIndex].reduce(0) { partialResult, cell in
            (cell == .Car) ? (partialResult + 1) : partialResult
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
        laneCuePlayer?.setVolume(volume)
    }

    public func stopAllSounds(fadeDuration: TimeInterval = 0.15) {
        soundPlayer?.stopAll(fadeDuration: fadeDuration)
        laneCuePlayer?.stopAll(fadeDuration: fadeDuration)
    }

    public func setAudioFeedbackMode(_ mode: AudioFeedbackMode) {
        audioFeedbackMode = mode
    }

    public func setLaneMoveCueStyle(_ style: LaneMoveCueStyle) {
        laneMoveCueStyle = style
    }

    public func setBigRivalCarsEnabled(_ enabled: Bool) {
        guard bigRivalCarsEnabled != enabled else { return }
        bigRivalCarsEnabled = enabled
        guard hasConfiguredScene else { return }
        gridStateDidUpdate(
            gridState,
            shouldPlayFeedback: false,
            notifyDelegate: false
        )
    }

    /// Plays the speed-warning chirp (three ascending lane notes).
    public func playSpeedIncreaseWarningSound() {
        laneCuePlayer?.playSpeedWarningCue()
    }

    private func playStartThenUnpause() {
        updatePauseState(true)
        startUnpauseFallbackTask?.cancel()
        applyStartPulseToPlayerCar()
        play(.start) { [weak self] in
            self?.finishStartPlaybackIfNeeded()
        }
        startUnpauseFallbackTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.startPlaybackFallbackDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.finishStartPlaybackIfNeeded()
        }
    }

    private func finishStartPlaybackIfNeeded() {
        guard gameState.isPaused else { return }
        guard isOverlayPauseLocked == false else { return }
        stopStartPulseOnPlayerCar()
        startUnpauseFallbackTask?.cancel()
        startUnpauseFallbackTask = nil
        updatePauseState(false)
    }

    private func resolveCrashIfNeeded() {
        guard isWaitingForCrashResolution else { return }
        isWaitingForCrashResolution = false
        crashResolutionFallbackTask?.cancel()
        crashResolutionFallbackTask = nil
        gameDelegate?.gameSceneDidDetectCollision(self)
    }

    private func cancelCrashResolutionIfNeeded() {
        isWaitingForCrashResolution = false
        crashResolutionFallbackTask?.cancel()
        crashResolutionFallbackTask = nil
    }

    func playFeedback(event: AudioFeedbackEvent) {
        switch audioFeedbackMode {
        case .retro:
            playRetroFeedback(event: event)
        case .cueChord, .cueArpeggio, .cueLanePulses:
            guard let laneCuePlayer else {
                play(.bip)
                return
            }

            switch event {
            case .tick:
                laneCuePlayer.playTickCue(safeColumns: safeColumnsAheadOfPlayer(), mode: audioFeedbackMode)
            case .move(let destinationColumn):
                if laneMoveCueStyle == .haptics {
                    let isSafe = isSafeDestinationColumn(destinationColumn)
                    if isSafe {
                        hapticController?.triggerSuccessHaptic()
                    } else {
                        hapticController?.triggerMoveHaptic()
                    }
                    return
                }
                guard let column = cueColumn(for: destinationColumn) else { return }
                let isSafe = isSafeDestinationColumn(destinationColumn)
                laneCuePlayer.playMoveCue(
                    column: column,
                    isSafe: isSafe,
                    mode: audioFeedbackMode,
                    style: laneMoveCueStyle
                )
            }
        }
    }

    private func playRetroFeedback(event: AudioFeedbackEvent) {
        guard let laneCuePlayer else {
            play(.bip)
            return
        }

        switch event {
        case .tick:
            laneCuePlayer.playTickCue(
                safeColumns: Set(CueColumn.allCases),
                mode: .cueArpeggio
            )
        case .move:
            laneCuePlayer.playMoveCue(
                column: .middle,
                isSafe: true,
                mode: .cueArpeggio,
                style: .laneConfirmation
            )
        }
    }

    private func safeColumnsAheadOfPlayer() -> Set<CueColumn> {
        let candidateRow = gridState.playerRowIndex - 1
        guard candidateRow >= 0, candidateRow < gridState.numberOfRows else {
            return Set(CueColumn.allCases)
        }

        var safeColumns: Set<CueColumn> = []
        for column in 0..<gridState.numberOfColumns {
            guard let cueColumn = cueColumn(for: column) else { continue }
            if gridState.grid[candidateRow][column] != .Car {
                safeColumns.insert(cueColumn)
            }
        }
        return safeColumns
    }

    private func isSafeDestinationColumn(_ destinationColumn: Int) -> Bool {
        let candidateRow = gridState.playerRowIndex - 1
        guard candidateRow >= 0,
              candidateRow < gridState.numberOfRows,
              destinationColumn >= 0,
              destinationColumn < gridState.numberOfColumns else {
            return true
        }

        return gridState.grid[candidateRow][destinationColumn] != .Car
    }

    private func cueColumn(for column: Int) -> CueColumn? {
        CueColumn(rawValue: column)
    }
}

extension GameScene: RacingGameController {
    public func moveLeft() {
        guard !gameState.isPaused else { return }

        let previousColumn = lastPlayerColumn
        (gridState, _) = gridCalculator.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .left)])
        lastPlayerColumn = gridState.playerRow().firstIndex(of: .Player) ?? lastPlayerColumn

        AppLog.info(AppLog.game, "🎮 GameScene.moveLeft from column \(String(describing: previousColumn)) to \(String(describing: lastPlayerColumn))")
        gridStateDidUpdate(
            gridState,
            shouldPlayFeedback: true,
            notifyDelegate: false,
            feedbackEvent: .move(destinationColumn: lastPlayerColumn)
        )
    }

    public func moveRight() {
        guard !gameState.isPaused else { return }

        let previousColumn = lastPlayerColumn
        (gridState, _) = gridCalculator.nextGrid(previousGrid: gridState, actions: [.moveCar(direction: .right)])
        lastPlayerColumn = gridState.playerRow().firstIndex(of: .Player) ?? lastPlayerColumn

        AppLog.info(AppLog.game, "🎮 GameScene.moveRight from column \(String(describing: previousColumn)) to \(String(describing: lastPlayerColumn))")
        gridStateDidUpdate(
            gridState,
            shouldPlayFeedback: true,
            notifyDelegate: false,
            feedbackEvent: .move(destinationColumn: lastPlayerColumn)
        )
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
        if shouldUseSceneManagedMoveHaptics == false {
            hapticController?.triggerMoveHaptic()
        }
        controller.moveLeft()
    }

    public func handleRight() {
        if shouldUseSceneManagedMoveHaptics == false {
            hapticController?.triggerMoveHaptic()
        }
        controller.moveRight()
    }

    public func handleDrag(translation: CGSize) {
        guard translation.width != 0 else { return }
        translation.width < 0 ? handleLeft() : handleRight()
    }

    private var shouldUseSceneManagedMoveHaptics: Bool {
        guard let scene = controller as? GameScene else { return false }
        guard scene.audioFeedbackMode != .retro else { return false }
        return scene.laneMoveCueStyle == .haptics
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
        if shouldUseSceneManagedMoveHaptics == false {
            hapticController?.triggerMoveHaptic()
        }
        controller.moveLeft()
    }

    public func handleRight() {
        if shouldUseSceneManagedMoveHaptics == false {
            hapticController?.triggerMoveHaptic()
        }
        controller.moveRight()
    }

    public func handleDrag(translation: CGSize) {
        guard translation.width != 0 else { return }
        translation.width < 0 ? handleLeft() : handleRight()
    }

    private var shouldUseSceneManagedMoveHaptics: Bool {
        guard let scene = controller as? GameScene else { return false }
        guard scene.audioFeedbackMode != .retro else { return false }
        return scene.laneMoveCueStyle == .haptics
    }
}

public struct CrownGameInputAdapter: GameInputAdapter {
    private let controller: RacingGameController

    public init(controller: RacingGameController) {
        self.controller = controller
    }

    public func handleLeft() {
        AppLog.info(AppLog.game, "🎮 CrownGameInputAdapter.handleLeft forwarding to controller")
        controller.moveLeft()
    }

    public func handleRight() {
        AppLog.info(AppLog.game, "🎮 CrownGameInputAdapter.handleRight forwarding to controller")
        controller.moveRight()
    }

    public func handleDrag(translation: CGSize) { }
}
