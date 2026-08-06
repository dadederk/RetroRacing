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

private enum AudioFallbackConfiguration {
    static let startUnpauseSeconds: TimeInterval = 2.0
    // Keep above fail-sound duration for missing-completion edge cases.
    static let crashResolutionSeconds: TimeInterval = 8.0
}

/// Input commands for the game. Named to avoid shadowing the GameController framework (physical controllers).
@MainActor
public protocol RacingGameController {
    func moveLeft()
    func moveRight()
}

enum AudioFeedbackEvent {
    case tick
    case move(destinationColumn: Int)
}

enum LineMode: Equatable {
    case detailedRoad
    case verticalOnly
}

enum LaneMoveRenderPath: String {
    case unchanged
    case incremental
    case fullRenderFallback = "full_render_fallback"
}

enum GameSpriteNodeName {
    static let playerCar = "player_car"
    static let crash = "crash"
}

private enum LaneMovePerformanceDiagnostics {
    @discardableResult
    static func measure(
        direction: String,
        operation: () -> LaneMoveRenderPath
    ) -> LaneMoveRenderPath {
        #if DEBUG
        let start = ContinuousClock.now
        let renderPath = operation()
        let duration = ContinuousClock.now - start
        guard duration >= .milliseconds(16) else { return renderPath }

        let components = duration.components
        let milliseconds = (Double(components.seconds) * 1_000)
            + (Double(components.attoseconds) / 1_000_000_000_000_000)
        AppLog.warning(
            AppLog.input + AppLog.game,
            "LANE_MOVE_EXCEEDED_FRAME_BUDGET",
            outcome: .completed,
            fields: [
                .string("direction", direction),
                .string("renderPath", renderPath.rawValue),
                .double("durationMilliseconds", milliseconds)
            ]
        )
        return renderPath
        #else
        return operation()
        #endif
    }
}

struct RoadSurfaceRenderSignature: Equatable {
    let sceneSize: CGSize
    let themeID: ThemeID?
    let roadVisualStyle: RoadVisualStyle
    let bigRivalCarsEnabled: Bool
    let lineMode: LineMode
}

struct TextureResolutionKey: Hashable {
    let requestedName: String
    let fallbackName: String
}

/// SpriteKit renderer that adapts shared engine snapshots and owns platform feedback.
@MainActor
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
    public private(set) var roadVisualStyle: RoadVisualStyle = .defaultStyle

    private var lastGameUpdateTime: TimeInterval?
    private var hasConfiguredScene = false
    var lastConfiguredSize: CGSize?
    private var startUnpauseFallbackTask: Task<Void, Never>?
    private var crashResolutionFallbackTask: Task<Void, Never>?
    private var isWaitingForCrashResolution = false
    private var isEngineManagedCollision = false
    private var isOverlayPauseLocked = false
    /// When true, crash sprites render fully opaque without the gameplay blink animation.
    var rendersStaticCrashForScreenshot = false
    private var showsDebugFrameStats = false
    #if !os(watchOS)
    private weak var hostingView: SKView?
    #endif

    var spritesForGivenState = [SKSpriteNode]()
    var playerSpriteNode: SKSpriteNode?
    var roadSurfaceNodes = [SKShapeNode]()
    var roadSurfaceRenderSignature: RoadSurfaceRenderSignature?
    var lineOverlayNodes = [SKNode]()
    var friendMilestoneOverlayNodes = [SKNode]()
    var cachedFriendAvatarTextures = [String: SKTexture]()
    var resolvedThemeTextures = [TextureResolutionKey: SKTexture]()
    var roadDashPhase = 0
    var safetyMarkerRows = [Int]()
    private var gameEngine: (any GameEngineProtocol)?
    private var hasLoggedMissingEngine = false
    var gridState = GridState(
        numberOfRows: GridConfiguration.numberOfRows,
        numberOfColumns: GridConfiguration.numberOfColumns
    )
    public private(set) var gameState = GameState()
    public private(set) var difficulty: GameDifficulty = .defaultDifficulty
    public private(set) var upcomingFriendMilestones = [UpcomingFriendMilestone]()
    public var upcomingFriendMilestone: UpcomingFriendMilestone? { upcomingFriendMilestones.first }
    var lastPlayerColumn: Int = 1
    private var lastLevelChangeImminent = false
    var lineMode: LineMode {
        if bigRivalCarsEnabled {
            return .verticalOnly
        }
        if roadVisualStyle == .simplifiedGrid {
            return .verticalOnly
        }
        return .detailedRoad
    }

    /// Number of points before level-up to show the speed-increasing alert; configurable, defaults to 3.
    public var speedAlertWindowPoints: Int = GameState.defaultSpeedAlertWindowPoints

    /// When set, sprite asset names and grid cell color come from the theme; otherwise LCD defaults.
    public var theme: (any GameTheme)? {
        didSet {
            guard oldValue?.id != theme?.id else { return }
            resolvedThemeTextures.removeAll()
            roadSurfaceRenderSignature = nil
        }
    }

    /// Loads sprite images from the bundle. Injected so shared code has no UIKit/AppKit conditionals.
    /// Optional so scene can be created before assignment; e.g. on watchOS sceneDidLoad() may run early.
    public var imageLoader: (any ImageLoader)? {
        didSet { resolvedThemeTextures.removeAll() }
    }

    /// Applies a theme change to the active scene without restarting gameplay state.
    public func updateTheme(_ theme: (any GameTheme)?) {
        guard self.theme?.id != theme?.id else { return }
        self.theme = theme
        if hasConfiguredScene {
            updateGrid(withGridState: gridState)
        }
    }

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
        bigRivalCarsEnabled: Bool = false,
        roadVisualStyle: RoadVisualStyle = .defaultStyle,
        gameEngine: any GameEngineProtocol
    ) {
        self.gameEngine = gameEngine
        super.init(size: size)
        self.theme = theme
        self.imageLoader = imageLoader
        self.soundPlayer = soundPlayer
        self.laneCuePlayer = laneCuePlayer
        self.hapticController = hapticController
        self.audioFeedbackMode = audioFeedbackMode
        self.laneMoveCueStyle = laneMoveCueStyle
        self.bigRivalCarsEnabled = bigRivalCarsEnabled
        self.roadVisualStyle = roadVisualStyle
        applyDifficulty(difficulty)
    }

    public override init(size: CGSize) {
        gameEngine = nil
        super.init(size: size)
        audioFeedbackMode = .defaultMode
        laneMoveCueStyle = .defaultStyle
    }

    public required init?(coder aDecoder: NSCoder) {
        gameEngine = nil
        super.init(coder: aDecoder)
        audioFeedbackMode = .defaultMode
        laneMoveCueStyle = .defaultStyle
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
        gameEngine: any GameEngineProtocol,
        theme: (any GameTheme)? = nil,
        imageLoader: some ImageLoader,
        soundPlayer: SoundEffectPlayer,
        laneCuePlayer: LaneCuePlayer? = nil,
        hapticController: HapticFeedbackController? = nil,
        audioFeedbackMode: AudioFeedbackMode = .defaultMode,
        laneMoveCueStyle: LaneMoveCueStyle = .defaultStyle,
        bigRivalCarsEnabled: Bool = false,
        roadVisualStyle: RoadVisualStyle = .defaultStyle
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
            bigRivalCarsEnabled: bigRivalCarsEnabled,
            roadVisualStyle: roadVisualStyle,
            gameEngine: gameEngine
        )
        scene.anchorPoint = CGPoint(x: 0, y: 0)
        scene.scaleMode = .aspectFit
        return scene
    }

    /// Creates a new game scene. Use programmatic size; .sks loading uses main bundle and is not used from framework.
    /// Caller must set imageLoader before presenting the scene if using this initializer.
    public class func newGameScene(
        difficulty: GameDifficulty,
        gameEngine: any GameEngineProtocol,
        imageLoader: some ImageLoader,
        soundPlayer: SoundEffectPlayer,
        laneCuePlayer: LaneCuePlayer? = nil,
        hapticController: HapticFeedbackController? = nil,
        audioFeedbackMode: AudioFeedbackMode = .defaultMode,
        laneMoveCueStyle: LaneMoveCueStyle = .defaultStyle,
        bigRivalCarsEnabled: Bool = false,
        roadVisualStyle: RoadVisualStyle = .defaultStyle
    ) -> GameScene {
        let defaultSize = CGSize(width: 800, height: 600)
        return scene(
            size: defaultSize,
            difficulty: difficulty,
            gameEngine: gameEngine,
            theme: nil,
            imageLoader: imageLoader,
            soundPlayer: soundPlayer,
            laneCuePlayer: laneCuePlayer,
            hapticController: hapticController,
            audioFeedbackMode: audioFeedbackMode,
            laneMoveCueStyle: laneMoveCueStyle,
            bigRivalCarsEnabled: bigRivalCarsEnabled,
            roadVisualStyle: roadVisualStyle
        )
    }

    /// Applies a new speed level without resetting score, lives, or grid state.
    public func applyDifficulty(_ difficulty: GameDifficulty) {
        self.difficulty = difficulty
        speedAlertWindowPoints = difficulty.speedAlertWindowPoints
        processEngineEvents(handleEngineCommand(.setDifficulty(difficulty)))
        let isImminent = GameState.isLevelChangeImminent(
            score: gameState.score,
            windowPoints: speedAlertWindowPoints
        )
        if isImminent != lastLevelChangeImminent {
            lastLevelChangeImminent = isImminent
            gameDelegate?.gameScene(self, levelChangeImminent: isImminent)
        }
    }

    /// Configures the scene to generate SharePlay hazard rows from a shared deterministic seed.
    public func configureSharePlayTraffic(seed: UInt64) {
        processEngineEvents(handleEngineCommand(.setTrafficMode(.seeded(seed))))
    }

    /// Restores solo traffic generation using the app's normal random source.
    public func configureRandomTraffic() {
        processEngineEvents(handleEngineCommand(.setTrafficMode(.random)))
    }

    public func start() {
        initialiseGame(playsStartSound: true)
    }

    /// Resets gameplay and starts immediately without the solo start cue. Used after the
    /// SharePlay synchronized countdown has already played its own start cue.
    public func startImmediately() {
        initialiseGame(playsStartSound: false)
    }

    /// Pauses gameplay without resetting grid or score. Used by user-facing pause control.
    public func pauseGameplay() {
        let reason: GamePauseReason = isOverlayPauseLocked ? .overlay : .user
        processEngineEvents(handleEngineCommand(.setPause(reason: reason, isActive: true)))
        synchronizeFromEngine()
    }

    /// Resumes gameplay after a user pause without resetting the grid.
    public func unpauseGameplay() {
        processEngineEvents(handleEngineCommand(.setPause(reason: .user, isActive: false)))
        synchronizeFromEngine()
    }

    /// Locks or unlocks pause state while the menu overlay is visible.
    public func setOverlayPauseLock(_ isLocked: Bool) {
        isOverlayPauseLocked = isLocked
        processEngineEvents(handleEngineCommand(.setPause(reason: .overlay, isActive: isLocked)))
        synchronizeFromEngine()
    }

    /// Stops gameplay permanently for a view/session dismissal.
    public func endGameplaySession(fadeDuration: TimeInterval) {
        isOverlayPauseLocked = true
        handleEngineCommand(.setPause(reason: .overlay, isActive: true))
        synchronizeFromEngine()
        isPaused = true
        cancelStartPlaybackIfNeeded()
        cancelCrashResolutionIfNeeded()
        stopStartPulseOnPlayerCar()
        stopAllSounds(fadeDuration: fadeDuration)
    }

    public func resume() {
        cancelCrashResolutionIfNeeded()
        handleEngineCommand(.setPause(reason: .user, isActive: false))
        synchronizeFromEngine()
        gridStateDidUpdate(gridState, shouldPlayFeedback: false, notifyDelegate: false)
        playStartThenUnpause()
    }

    func setUpScene() {
        AppLog.debug(
            AppLog.assets + AppLog.game,
            "SCENE_SETUP",
            outcome: .started,
            fields: [
                .string("bundlePath", AppLog.redactedPath(Self.sharedBundle.bundleURL.path)),
                .double("width", size.width),
                .double("height", size.height)
            ]
        )

        if hasConfiguredScene {
            resizeScene(to: size)
        } else {
            hasConfiguredScene = true
            lastConfiguredSize = size
            anchorPoint = CGPoint(x: 0, y: 0)
            scaleMode = .aspectFit
            backgroundColor = gameBackgroundColor
            AppLog.debug(
                AppLog.assets + AppLog.game,
                "SCENE_SETUP_ANCHOR",
                outcome: .completed,
                fields: [
                    .double("anchorX", anchorPoint.x),
                    .double("anchorY", anchorPoint.y)
                ]
            )
            createGrid()
            initialiseGame(playsStartSound: isOverlayPauseLocked == false)
        }
    }

#if os(watchOS)
    public override func sceneDidLoad() {
        setUpScene()
    }
#else
    public override func didMove(to view: SKView) {
        hostingView = view
        applyDebugFrameStatsIfNeeded()
        setUpScene()
    }
#endif

    public override func update(_ currentTime: TimeInterval) {
        guard gameEngine != nil else {
            logMissingEngineIfNeeded(operation: "tick")
            return
        }
        guard let previousUpdateTime = lastGameUpdateTime else {
            self.lastGameUpdateTime = currentTime
            return
        }
        let elapsedTime = currentTime - previousUpdateTime
        self.lastGameUpdateTime = currentTime
        guard elapsedTime.isFinite, elapsedTime > 0 else { return }
        guard isWaitingForCrashResolution == false else { return }

        let acceptedElapsedTime = min(elapsedTime, 0.25)
        guard let previousSnapshot = gameEngine?.snapshot else { return }
        let events = handleEngineCommand(.tick(elapsedTime: acceptedElapsedTime))
        guard let currentSnapshot = gameEngine?.snapshot else { return }
        guard previousSnapshot != currentSnapshot || events.isEmpty == false else { return }

        synchronizeFromEngine()
        processEngineEvents(events)
        gridStateDidUpdate(gridState)
    }

    private func synchronizeFromEngine() {
        guard let engineSnapshot = gameEngine?.snapshot else {
            logMissingEngineIfNeeded(operation: "synchronize")
            return
        }
        let wasPaused = gameState.isPaused
        var synchronizedGrid = GridState(
            numberOfRows: engineSnapshot.numberOfRows,
            numberOfColumns: engineSnapshot.numberOfColumns
        )
        synchronizedGrid.grid = engineSnapshot.grid.map { row in
            row.map { occupant in
                switch occupant {
                case .empty: .Empty
                case .rival: .Car
                case .player: .Player
                case .crash: .Crash
                }
            }
        }
        gridState = synchronizedGrid
        gameState.score = engineSnapshot.score
        gameState.lives = engineSnapshot.lives
        gameState.isPaused = engineSnapshot.isPaused
        roadDashPhase = engineSnapshot.roadPhase
        safetyMarkerRows = engineSnapshot.safetyMarkerRows
        difficulty = engineSnapshot.difficulty
        lastPlayerColumn = engineSnapshot.playerColumn
        if wasPaused != gameState.isPaused {
            gameDelegate?.gameScene(self, didUpdatePauseState: gameState.isPaused)
        }
    }

    @discardableResult
    private func handleEngineCommand(_ command: GameCommand) -> [GameEvent] {
        guard let gameEngine else {
            logMissingEngineIfNeeded(operation: "command")
            return []
        }
        return gameEngine.handle(command)
    }

    private func logMissingEngineIfNeeded(operation: String) {
        guard hasLoggedMissingEngine == false else { return }
        hasLoggedMissingEngine = true
        AppLog.critical(
            AppLog.game,
            "GAME_ENGINE_CONFIGURATION",
            outcome: .failed,
            fields: [
                .reason("missing_injected_engine"),
                .string("operation", operation)
            ]
        )
    }

    private func processEngineEvents(_ events: [GameEvent]) {
        for event in events {
            switch event {
            case .scoreChanged(let score):
                gameDelegate?.gameScene(self, didUpdateScore: score)
            case .collision:
                isEngineManagedCollision = true
                handleCrash()
            case .collisionResolved, .gameOver:
                finishEngineManagedCollisionIfNeeded()
            case .levelChangeImminent(let isImminent):
                lastLevelChangeImminent = isImminent
                gameDelegate?.gameScene(self, levelChangeImminent: isImminent)
            case .started, .laneChanged, .pauseChanged, .restarted, .finished:
                break
            }
        }
    }

    private func initialiseGame(playsStartSound: Bool) {
        lastGameUpdateTime = nil
        handleEngineCommand(.start)
        handleEngineCommand(.setPause(reason: .startup, isActive: playsStartSound))
        handleEngineCommand(.setPause(reason: .overlay, isActive: isOverlayPauseLocked))
        synchronizeFromEngine()
        if lastLevelChangeImminent {
            lastLevelChangeImminent = false
            gameDelegate?.gameScene(self, levelChangeImminent: false)
        }
        cancelCrashResolutionIfNeeded()
        gridStateDidUpdate(gridState, shouldPlayFeedback: false, notifyDelegate: false)
        if playsStartSound {
            playStartThenUnpause()
        } else {
            startWithoutStartSound()
        }
    }

    func handleCrash() {
        guard isWaitingForCrashResolution == false else { return }
        isWaitingForCrashResolution = true
        startUnpauseFallbackTask?.cancel()
        startUnpauseFallbackTask = nil
        synchronizeFromEngine()
        hapticController?.triggerCrashHaptic()
        updatePauseState(true)
        crashResolutionFallbackTask?.cancel()
        crashResolutionFallbackTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: UInt64(self.crashResolutionFallbackDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            self.resolveCrashIfNeeded()
        }
        play(.fail) { [weak self] in
            self?.resolveCrashIfNeeded()
        }
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

    public func setRoadVisualStyle(_ style: RoadVisualStyle) {
        guard roadVisualStyle != style else { return }
        roadVisualStyle = style
        guard hasConfiguredScene else { return }
        gridStateDidUpdate(
            gridState,
            shouldPlayFeedback: false,
            notifyDelegate: false
        )
    }

    /// Enables or disables SpriteKit frame diagnostics in the hosting `SKView`.
    public func setDebugFrameStatsEnabled(_ isEnabled: Bool) {
        let didChange = showsDebugFrameStats != isEnabled
        showsDebugFrameStats = isEnabled
        if didChange {
            AppLog.info(
                AppLog.game,
                "SPRITEKIT_FRAME_DIAGNOSTICS",
                outcome: .completed,
                fields: [
                    .bool("enabled", isEnabled)
                ]
            )
        }
        applyDebugFrameStatsIfNeeded()
    }

    public func setUpcomingFriendMilestone(_ milestone: UpcomingFriendMilestone?) {
        setUpcomingFriendMilestones(milestone.map { [$0] } ?? [])
    }

    public func setUpcomingFriendMilestones(_ milestones: [UpcomingFriendMilestone]) {
        guard upcomingFriendMilestones != milestones else { return }
        upcomingFriendMilestones = milestones
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

    private func applyDebugFrameStatsIfNeeded() {
        #if !os(watchOS)
        guard let hostingView else { return }
        hostingView.showsFPS = showsDebugFrameStats
        hostingView.showsNodeCount = showsDebugFrameStats
        #endif
    }

    private func playStartThenUnpause() {
        isPaused = false
        updatePauseState(true)
        cancelStartPlaybackIfNeeded()
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

    private func startWithoutStartSound() {
        isPaused = false
        stopStartPulseOnPlayerCar()
        cancelStartPlaybackIfNeeded()
        processEngineEvents(handleEngineCommand(.setPause(reason: .startup, isActive: false)))
        synchronizeFromEngine()
    }

    private func finishStartPlaybackIfNeeded() {
        guard gameState.isPaused else { return }
        guard isOverlayPauseLocked == false else { return }
        stopStartPulseOnPlayerCar()
        cancelStartPlaybackIfNeeded()
        processEngineEvents(handleEngineCommand(.setPause(reason: .startup, isActive: false)))
        synchronizeFromEngine()
    }

    private func resolveCrashIfNeeded() {
        guard isWaitingForCrashResolution else { return }
        if isEngineManagedCollision {
            let events = handleEngineCommand(.resolveCollision)
            synchronizeFromEngine()
            processEngineEvents(events)
            gridStateDidUpdate(gridState, shouldPlayFeedback: false)
            return
        }

        isWaitingForCrashResolution = false
        crashResolutionFallbackTask?.cancel()
        crashResolutionFallbackTask = nil
        gameDelegate?.gameSceneDidDetectCollision(self)
    }

    private func finishEngineManagedCollisionIfNeeded() {
        guard isEngineManagedCollision else { return }
        isWaitingForCrashResolution = false
        isEngineManagedCollision = false
        crashResolutionFallbackTask?.cancel()
        crashResolutionFallbackTask = nil
        gameDelegate?.gameSceneDidDetectCollision(self)
    }

    private func cancelCrashResolutionIfNeeded() {
        isWaitingForCrashResolution = false
        isEngineManagedCollision = false
        crashResolutionFallbackTask?.cancel()
        crashResolutionFallbackTask = nil
    }

    private func cancelStartPlaybackIfNeeded() {
        startUnpauseFallbackTask?.cancel()
        startUnpauseFallbackTask = nil
    }

    func playFeedback(event: AudioFeedbackEvent) {
        switch audioFeedbackMode {
        case .retro:
            playRetroFeedback(event: event)
        case .cueChord, .cueArpeggio, .cueLanePulses:
            guard let laneCuePlayer else {
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
        switch event {
        case .tick:
            guard let laneCuePlayer else { return }
            laneCuePlayer.playTickCue(safeColumns: Set(CueColumn.allCases), mode: .cueArpeggio)
        case .move:
            guard let laneCuePlayer else { return }
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

    public func applyScreenshotLayout(_ layout: GameScreenshotLayout) {
        prepareGridForScreenshotLayout(expectedState: layout.gridState)
        let playerColumn = layout.gridState.playerRow().firstIndex(of: .Player)
            ?? layout.gridState.playerRow().firstIndex(of: .Crash)
            ?? 1
        let snapshot = GameSnapshot.fixture(
            phase: layout.gridState.hasCrashed ? .collision : .paused,
            grid: layout.gridState.grid.map { row in
                row.map { cell in
                    switch cell {
                    case .Empty: .empty
                    case .Car: .rival
                    case .Player: .player
                    case .Crash: .crash
                    }
                }
            },
            playerColumn: playerColumn,
            score: layout.score,
            lives: layout.lives,
            level: (layout.score / GameState.levelStep) + 1,
            roadPhase: 0,
            safetyMarkerRows: layout.safetyMarkerRows,
            difficulty: difficulty,
            activePauseReasons: [.overlay]
        )
        if let snapshot,
           let fixtureEngine = gameEngine as? GameEngine,
           fixtureEngine.applyFixture(snapshot) {
            synchronizeFromEngine()
        } else {
            gridState = layout.gridState
            safetyMarkerRows = layout.safetyMarkerRows
            gameState.score = layout.score
            gameState.lives = layout.lives
            gameState.isPaused = true
            lastPlayerColumn = playerColumn
            AppLog.warning(
                AppLog.game,
                "GAME_ENGINE_SCREENSHOT_FIXTURE",
                outcome: .failed,
                fields: [.reason("fixture_engine_unavailable")]
            )
        }
        setUpcomingFriendMilestones(layout.upcomingMilestones)
        rendersStaticCrashForScreenshot = layout.gridState.hasCrashed
        gridStateDidUpdate(
            gridState,
            shouldPlayFeedback: false,
            notifyDelegate: false
        )
        if rendersStaticCrashForScreenshot {
            solidifyCrashSpritesForScreenshotCapture()
        }
        setOverlayPauseLock(true)
        pauseGameplay()
    }

    public var isReadyToApplyScreenshotLayout: Bool {
        guard hasConfiguredScene else { return false }
        guard size.width > 1, size.height > 1 else { return false }
        #if os(watchOS)
        return childNode(withName: nameForCell(column: 0, row: 0)) != nil
        #else
        return hostingView != nil
            && childNode(withName: nameForCell(column: 0, row: 0)) != nil
        #endif
    }

    private func prepareGridForScreenshotLayout(expectedState: GridState) {
        let gridCellExists = childNode(withName: nameForCell(column: 0, row: 0)) != nil
        let dimensionsMatch = gridState.numberOfRows == expectedState.numberOfRows
            && gridState.numberOfColumns == expectedState.numberOfColumns

        if hasConfiguredScene, gridCellExists, dimensionsMatch {
            return
        }

        removeAllChildren()
        spritesForGivenState.removeAll()
        playerSpriteNode = nil
        roadSurfaceNodes.removeAll()
        roadSurfaceRenderSignature = nil
        lineOverlayNodes.removeAll()
        friendMilestoneOverlayNodes.removeAll()

        hasConfiguredScene = true
        lastConfiguredSize = size
        anchorPoint = CGPoint(x: 0, y: 0)
        scaleMode = .aspectFit
        backgroundColor = gameBackgroundColor
        gridState = expectedState
        createGrid()
    }
}

extension GameScene: RacingGameController {
    public func moveLeft() {
        guard !gameState.isPaused else { return }

        let previousColumn = lastPlayerColumn
        LaneMovePerformanceDiagnostics.measure(direction: "left") {
            let events = handleEngineCommand(.move(.left))
            synchronizeFromEngine()
            processEngineEvents(events)
            return playerLaneDidUpdate(
                fromColumn: previousColumn,
                toColumn: lastPlayerColumn
            )
        }
    }

    public func moveRight() {
        guard !gameState.isPaused else { return }

        let previousColumn = lastPlayerColumn
        LaneMovePerformanceDiagnostics.measure(direction: "right") {
            let events = handleEngineCommand(.move(.right))
            synchronizeFromEngine()
            processEngineEvents(events)
            return playerLaneDidUpdate(
                fromColumn: previousColumn,
                toColumn: lastPlayerColumn
            )
        }
    }
}

// MARK: - Input adapters

@MainActor
public protocol GameInputAdapter {
    func handleLeft()
    func handleRight()
    func handleDrag(translation: CGSize)
}

@MainActor
private struct DirectionalGameInputAdapterCore {
    let controller: RacingGameController
    let hapticController: HapticFeedbackController?

    func handleLeft() {
        let shouldTriggerMoveHaptic = shouldUseSceneManagedMoveHaptics == false
        controller.moveLeft()
        if shouldTriggerMoveHaptic {
            hapticController?.triggerMoveHaptic()
        }
    }

    func handleRight() {
        let shouldTriggerMoveHaptic = shouldUseSceneManagedMoveHaptics == false
        controller.moveRight()
        if shouldTriggerMoveHaptic {
            hapticController?.triggerMoveHaptic()
        }
    }

    func handleDrag(translation: CGSize) {
        guard translation.width != 0 else { return }
        translation.width < 0 ? handleLeft() : handleRight()
    }

    private var shouldUseSceneManagedMoveHaptics: Bool {
        guard let scene = controller as? GameScene else { return false }
        guard scene.audioFeedbackMode != .retro else { return false }
        return scene.laneMoveCueStyle == .haptics
    }
}

public struct TouchGameInputAdapter: GameInputAdapter {
    private let core: DirectionalGameInputAdapterCore

    public init(controller: RacingGameController, hapticController: HapticFeedbackController?) {
        self.core = DirectionalGameInputAdapterCore(
            controller: controller,
            hapticController: hapticController
        )
    }

    public func handleLeft() {
        core.handleLeft()
    }

    public func handleRight() {
        core.handleRight()
    }

    public func handleDrag(translation: CGSize) {
        core.handleDrag(translation: translation)
    }
}

public struct RemoteGameInputAdapter: GameInputAdapter {
    private let core: DirectionalGameInputAdapterCore

    public init(controller: RacingGameController, hapticController: HapticFeedbackController?) {
        self.core = DirectionalGameInputAdapterCore(
            controller: controller,
            hapticController: hapticController
        )
    }

    public func handleLeft() {
        core.handleLeft()
    }

    public func handleRight() {
        core.handleRight()
    }

    public func handleDrag(translation: CGSize) {
        core.handleDrag(translation: translation)
    }
}

public struct CrownGameInputAdapter: GameInputAdapter {
    private let controller: RacingGameController
    private let hapticController: HapticFeedbackController?

    public init(controller: RacingGameController, hapticController: HapticFeedbackController?) {
        self.controller = controller
        self.hapticController = hapticController
    }

    public func handleLeft() {
        guard let scene = controller as? GameScene else {
            controller.moveLeft()
            return
        }
        let didMove = moveLeftAndDetectLaneChange(in: scene)
        if didMove, shouldUseSceneManagedMoveHaptics(in: scene) == false {
            hapticController?.triggerMoveHaptic()
        }
    }

    public func handleRight() {
        guard let scene = controller as? GameScene else {
            controller.moveRight()
            return
        }
        let didMove = moveRightAndDetectLaneChange(in: scene)
        if didMove, shouldUseSceneManagedMoveHaptics(in: scene) == false {
            hapticController?.triggerMoveHaptic()
        }
    }

    public func handleDrag(translation: CGSize) { }

    private func moveLeftAndDetectLaneChange(in scene: GameScene) -> Bool {
        let previousColumn = scene.lastPlayerColumn
        scene.moveLeft()
        let didMove = scene.lastPlayerColumn != previousColumn
        AppLog.debug(
            AppLog.input + AppLog.game,
            "CROWN_ADAPTER_MOVE_LEFT",
            outcome: .completed,
            fields: [
                .bool("didMove", didMove),
                .int("from", previousColumn),
                .int("to", scene.lastPlayerColumn)
            ]
        )
        return didMove
    }

    private func moveRightAndDetectLaneChange(in scene: GameScene) -> Bool {
        let previousColumn = scene.lastPlayerColumn
        scene.moveRight()
        let didMove = scene.lastPlayerColumn != previousColumn
        AppLog.debug(
            AppLog.input + AppLog.game,
            "CROWN_ADAPTER_MOVE_RIGHT",
            outcome: .completed,
            fields: [
                .bool("didMove", didMove),
                .int("from", previousColumn),
                .int("to", scene.lastPlayerColumn)
            ]
        )
        return didMove
    }

    private func shouldUseSceneManagedMoveHaptics(in scene: GameScene) -> Bool {
        guard scene.audioFeedbackMode != .retro else { return false }
        return scene.laneMoveCueStyle == .haptics
    }
}
