import SwiftUI
import SpriteKit
import RetroRacingShared

struct WatchGameView: View {
    let theme: any GameTheme
    let fontPreferenceStore: FontPreferenceStore?
    let highestScoreStore: HighestScoreStore
    let crownConfiguration: LegacyCrownInputProcessor.Configuration
    let leaderboardService: LeaderboardService
    @AppStorage(GameDifficulty.conditionalDefaultStorageKey) private var difficultyStorageData: Data = Data()
    @AppStorage(SoundPreferences.volumeKey) private var sfxVolume: Double = SoundPreferences.defaultVolume
    @AppStorage(AudioFeedbackMode.conditionalDefaultStorageKey) private var audioFeedbackModeStorageData: Data = Data()
    @AppStorage(LaneMoveCueStyle.storageKey) private var laneMoveCueStyleRawValue: String = LaneMoveCueStyle.defaultStyle.rawValue
    @AppStorage(VoiceOverTutorialPreference.hasSeenInGameVoiceOverTutorialKey)
    private var hasSeenInGameVoiceOverTutorial: Bool = VoiceOverTutorialPreference.defaultHasSeenInGameVoiceOverTutorial
    @State private var scene: GameScene
    @State private var crownValue: Double = 0
    @State private var crownProcessor: LegacyCrownInputProcessor
    @State private var crownIdleTask: Task<Void, Never>?
    @State private var score: Int = 0
    @State private var lives: Int = 3
    @State private var scenePaused: Bool = false
    @State private var isUserPaused: Bool = false
    @State private var showGameOver = false
    @State private var gameOverScore: Int = 0
    @State private var gameOverBestScore: Int = 0
    @State private var gameOverDifficulty: GameDifficulty = .defaultDifficulty
    @State private var gameOverPreviousBestScore: Int?
    @State private var isNewHighScore = false
    @State private var delegate: GameSceneDelegateImpl?
    @State private var inputAdapter: GameInputAdapter?
    @State private var isInGameHelpPresented = false
    @State private var helpPresentationContext: HelpPresentationContext?
    @FocusState private var isCrownFocused: Bool
    @Environment(\.dismiss) private var dismiss

    private enum HelpPresentationContext {
        case manual(snapshot: HelpPauseSnapshot)
        case automatic(shouldResumeOnDismiss: Bool)
    }

    private struct HelpPauseSnapshot {
        let wasScenePaused: Bool
        let wasUserPaused: Bool
    }

    private var pauseButtonDisabled: Bool {
        scenePaused && isUserPaused == false
    }

    init(
        theme: any GameTheme,
        fontPreferenceStore: FontPreferenceStore? = nil,
        highestScoreStore: HighestScoreStore,
        crownConfiguration: LegacyCrownInputProcessor.Configuration,
        leaderboardService: LeaderboardService
    ) {
        self.theme = theme
        self.fontPreferenceStore = fontPreferenceStore
        self.highestScoreStore = highestScoreStore
        self.crownConfiguration = crownConfiguration
        self.leaderboardService = leaderboardService
        let initialDifficulty = GameDifficulty.currentSelection(from: InfrastructureDefaults.userDefaults)
        let initialAudioFeedbackMode = AudioFeedbackMode.currentSelection(from: InfrastructureDefaults.userDefaults)
        let initialLaneMoveCueStyle = LaneMoveCueStyle.currentSelection(from: InfrastructureDefaults.userDefaults)
        let size = CGSize(width: 400, height: 300)
        let soundPlayer = PlatformFactories.makeSoundPlayer()
        let laneCuePlayer = PlatformFactories.makeLaneCuePlayer()
        soundPlayer.setVolume(SoundPreferences.defaultVolume)
        laneCuePlayer.setVolume(SoundPreferences.defaultVolume)
        _scene = State(initialValue: GameScene.scene(
            size: size,
            difficulty: initialDifficulty,
            theme: theme,
            imageLoader: PlatformFactories.makeImageLoader(),
            soundPlayer: soundPlayer,
            laneCuePlayer: laneCuePlayer,
            hapticController: nil,
            audioFeedbackMode: initialAudioFeedbackMode,
            laneMoveCueStyle: initialLaneMoveCueStyle
        ))
        _crownProcessor = State(initialValue: LegacyCrownInputProcessor(configuration: crownConfiguration))
    }

    private func headerFont(size: CGFloat = 10) -> Font {
        fontPreferenceStore?.font(fixedSize: size) ?? .custom("PressStart2P-Regular", size: size)
    }

    private static let sharedBundle = Bundle(for: GameScene.self)

    private static let crownIdleResetDelay: Duration = .milliseconds(150)

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(GameLocalizedStrings.format("score %lld", score))
                    .font(headerFont(size: 10))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .allowsTightening(true)
                Spacer()
                HStack(spacing: 2) {
                    Image(theme.lifeSprite() ?? "life", bundle: Self.sharedBundle)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                    Text(GameLocalizedStrings.format("lives_count", lives))
                        .font(headerFont(size: 10))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .allowsTightening(true)
                }
            }
            .frame(minHeight: 20)
            .layoutPriority(1)
            GeometryReader { geo in
                ZStack {
                    SpriteView(scene: scene)
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(coordinateSpace: .local) { location in
                            if location.x < geo.size.width / 2 {
                                AppLog.info(AppLog.game, "🎮 Watch tap on left half (x: \(location.x), width: \(geo.size.width))")
                                inputAdapter?.handleLeft()
                            } else {
                                AppLog.info(AppLog.game, "🎮 Watch tap on right half (x: \(location.x), width: \(geo.size.width))")
                                inputAdapter?.handleRight()
                            }
                            // Ensure the crown stays focused after a tap interaction.
                            AppLog.info(AppLog.game, "🎮 Watch tap reasserting crown focus")
                            isCrownFocused = true
                        }
                        .gesture(
                            DragGesture(minimumDistance: 20)
                                .onEnded { value in
                                    guard value.translation.width != 0 else { return }
                                    let direction = value.translation.width < 0 ? "left" : "right"
                                    AppLog.info(
                                        AppLog.game,
                                        "🎮 Watch swipe \(direction) with translation: \(value.translation.width)"
                                    )
                                    if value.translation.width < 0 {
                                        inputAdapter?.handleLeft()
                                    } else {
                                        inputAdapter?.handleRight()
                                    }
                                    // Ensure the crown stays focused after a swipe interaction.
                                    AppLog.info(AppLog.game, "🎮 Watch swipe reasserting crown focus")
                                    isCrownFocused = true
                                }
                        )
                }
                .focusable()
                .focused($isCrownFocused)
                .digitalCrownRotation(
                    $crownValue,
                    from: -100,
                    through: 100,
                    by: 0.1,
                    sensitivity: .low,
                    isContinuous: true,
                    isHapticFeedbackEnabled: true
                )
                .onChange(of: isCrownFocused) { _, newValue in
                    AppLog.info(AppLog.game, "🎮 Watch crown focus changed: \(newValue)")
                }
                .onChange(of: crownValue, initial: false) { oldValue, newValue in
                    let delta = newValue - oldValue
                    AppLog.info(AppLog.game, "🎮 Watch crown value changed: old=\(oldValue), new=\(newValue), delta=\(delta)")
                    handleCrownDelta(delta)
                }
            }
        }
        .onAppear {
            AppLog.info(AppLog.game, "🎮 WatchGameView onAppear - setting up scene and crown focus")
            scene.applyDifficulty(selectedDifficulty)
            scene.setSoundVolume(sfxVolume)
            scene.setAudioFeedbackMode(selectedAudioFeedbackMode)
            scene.setLaneMoveCueStyle(selectedLaneMoveCueStyle)
            scene.start()
            score = scene.gameState.score
            lives = scene.gameState.lives
            scenePaused = scene.gameState.isPaused
            inputAdapter = CrownGameInputAdapter(controller: scene)
            isCrownFocused = true
            if delegate == nil {
                let d = GameSceneDelegateImpl(
                    onScoreUpdate: { score = $0 },
                    onCollision: {
                        lives = scene.gameState.lives
                        if scene.gameState.lives == 0 {
                            gameOverScore = scene.gameState.score
                            let authenticated = leaderboardService.isAuthenticated()
                            AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS game over – score \(gameOverScore), Game Center authenticated: \(authenticated)")
                            let difficultyAtGameOver = selectedDifficulty
                            leaderboardService.submitScore(gameOverScore, difficulty: difficultyAtGameOver)
                            let summary = highestScoreStore.evaluateGameOverScore(gameOverScore, difficulty: difficultyAtGameOver)
                            isNewHighScore = summary.isNewRecord
                            gameOverBestScore = summary.bestScore
                            gameOverDifficulty = difficultyAtGameOver
                            gameOverPreviousBestScore = summary.previousBestScore
                            showGameOver = true
                        } else {
                            scene.resume()
                        }
                    },
                    onPauseStateChange: { scenePaused = $0 }
                )
                delegate = d
                scene.gameDelegate = d
            }
            attemptAutoPresentVoiceOverHelpIfNeeded()
        }
        .sheet(isPresented: $isInGameHelpPresented, onDismiss: handleInGameHelpDismissed) {
            InGameHelpView(controlsDescriptionKey: "settings_controls_watchos")
                .fontPreferenceStore(fontPreferenceStore)
        }
        .sheet(isPresented: $showGameOver, onDismiss: restartFromGameOver) {
            GameOverView(
                score: gameOverScore,
                bestScore: gameOverBestScore,
                difficulty: gameOverDifficulty,
                isNewRecord: isNewHighScore,
                previousBestScore: gameOverPreviousBestScore,
                onRestart: restartFromGameOver,
                onFinish: finishFromGameOver
            )
            .fontPreferenceStore(fontPreferenceStore)
            .interactiveDismissDisabled(true)
        }
        .onDisappear {
            scene.stopAllSounds()
            crownIdleTask?.cancel()
            crownIdleTask = nil
        }
        .onChange(of: sfxVolume) { _, newValue in
            scene.setSoundVolume(newValue)
        }
        .onChange(of: difficultyStorageData) { _, _ in
            scene.applyDifficulty(selectedDifficulty)
        }
        .onChange(of: audioFeedbackModeStorageData) { _, _ in
            scene.setAudioFeedbackMode(selectedAudioFeedbackMode)
        }
        .onChange(of: laneMoveCueStyleRawValue) { _, _ in
            scene.setLaneMoveCueStyle(selectedLaneMoveCueStyle)
        }
        .onChange(of: scenePaused) { _, _ in
            attemptAutoPresentVoiceOverHelpIfNeeded()
        }
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    presentManualHelp()
                } label: {
                    Image(systemName: "questionmark.circle")
                }
                .accessibilityLabel(GameLocalizedStrings.string("tutorial_help_button"))
                .buttonStyle(.glass)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    togglePause()
                } label: {
                    Image(systemName: isUserPaused ? "play.fill" : "pause.fill")
                }
                .accessibilityLabel(GameLocalizedStrings.string(isUserPaused ? "resume" : "pause"))
                .disabled(pauseButtonDisabled)
                .opacity(pauseButtonDisabled ? 0.4 : 1)
                .buttonStyle(.glass)
            }
        }
        .accessibilityAction(.magicTap) {
            togglePause()
        }
    }

    private func togglePause() {
        guard pauseButtonDisabled == false else { return }
        if isUserPaused {
            scene.unpauseGameplay()
            isUserPaused = false
        } else {
            scene.pauseGameplay()
            isUserPaused = true
        }
    }

    private func restartFromGameOver() {
        scene.start()
        score = scene.gameState.score
        lives = scene.gameState.lives
        showGameOver = false
        gameOverScore = 0
        gameOverBestScore = 0
        gameOverDifficulty = selectedDifficulty
        gameOverPreviousBestScore = nil
        isNewHighScore = false
    }

    private func finishFromGameOver() {
        showGameOver = false
        dismiss()
    }

    private func attemptAutoPresentVoiceOverHelpIfNeeded() {
        guard InGameHelpPresentationPolicy.shouldAutoPresent(
            voiceOverRunning: VoiceOverStatus.isVoiceOverRunning,
            hasSeenTutorial: hasSeenInGameVoiceOverTutorial,
            shouldStartGame: true,
            hasScene: true,
            isScenePaused: scenePaused
        ) else { return }
        presentAutomaticHelp()
    }

    private func presentManualHelp() {
        let snapshot = beginManualHelpPresentation()
        helpPresentationContext = .manual(snapshot: snapshot)
        if VoiceOverStatus.isVoiceOverRunning {
            hasSeenInGameVoiceOverTutorial = true
        }
        isInGameHelpPresented = true
    }

    private func presentAutomaticHelp() {
        let shouldResumeOnDismiss = beginAutomaticHelpPresentation()
        helpPresentationContext = .automatic(shouldResumeOnDismiss: shouldResumeOnDismiss)
        hasSeenInGameVoiceOverTutorial = true
        isInGameHelpPresented = true
    }

    private func handleInGameHelpDismissed() {
        guard let helpPresentationContext else { return }
        switch helpPresentationContext {
        case .manual(let snapshot):
            endManualHelpPresentation(using: snapshot)
        case .automatic(let shouldResumeOnDismiss):
            endAutomaticHelpPresentation(shouldResumeOnDismiss: shouldResumeOnDismiss)
        }
        self.helpPresentationContext = nil
    }

    private func beginManualHelpPresentation() -> HelpPauseSnapshot {
        let snapshot = HelpPauseSnapshot(wasScenePaused: scenePaused, wasUserPaused: isUserPaused)
        scene.setOverlayPauseLock(true)
        if snapshot.wasScenePaused == false {
            scene.pauseGameplay()
        }
        return snapshot
    }

    private func beginAutomaticHelpPresentation() -> Bool {
        scene.setOverlayPauseLock(true)
        let shouldResumeOnDismiss = scene.gameState.isPaused == false
        if shouldResumeOnDismiss {
            scene.pauseGameplay()
        }
        return shouldResumeOnDismiss
    }

    private func endManualHelpPresentation(using snapshot: HelpPauseSnapshot) {
        scene.setOverlayPauseLock(false)
        isUserPaused = snapshot.wasUserPaused
        if snapshot.wasScenePaused {
            scene.pauseGameplay()
        } else {
            scene.unpauseGameplay()
        }
    }

    private func endAutomaticHelpPresentation(shouldResumeOnDismiss: Bool) {
        scene.setOverlayPauseLock(false)
        if shouldResumeOnDismiss && isUserPaused == false {
            scene.unpauseGameplay()
        }
    }

    private func handleCrownDelta(_ delta: Double) {
        let action = crownProcessor.handleRotationDelta(delta)
        AppLog.info(AppLog.game, "🎮 Watch crown delta \(delta) produced action: \(String(describing: action))")

        switch action {
        case .moveLeft:
            AppLog.info(AppLog.game, "🎮 Watch crown triggering moveLeft via adapter")
            inputAdapter?.handleLeft()
            scheduleCrownIdleReset()
        case .moveRight:
            AppLog.info(AppLog.game, "🎮 Watch crown triggering moveRight via adapter")
            inputAdapter?.handleRight()
            scheduleCrownIdleReset()
        case .none:
            break
        @unknown default:
            AppLog.error(AppLog.game, "🎮 Watch crown received unknown CrownInputAction: \(String(describing: action))")
        }
    }

    private func scheduleCrownIdleReset() {
        crownIdleTask?.cancel()
        crownIdleTask = Task { @MainActor in
            AppLog.info(AppLog.game, "🎮 Watch crown scheduling idle reset after \(Self.crownIdleResetDelay)")
            try? await Task.sleep(for: Self.crownIdleResetDelay)
            guard Task.isCancelled == false else {
                AppLog.info(AppLog.game, "🎮 Watch crown idle reset task cancelled")
                return
            }
            crownProcessor.markIdle()
            AppLog.info(AppLog.game, "🎮 Watch crown marked idle – rotation re-enabled")
        }
    }

    private var selectedDifficulty: GameDifficulty {
        GameDifficulty.currentSelection(from: InfrastructureDefaults.userDefaults)
    }

    private var selectedAudioFeedbackMode: AudioFeedbackMode {
        AudioFeedbackMode.currentSelection(from: InfrastructureDefaults.userDefaults)
    }

    private var selectedLaneMoveCueStyle: LaneMoveCueStyle {
        LaneMoveCueStyle.fromStoredValue(laneMoveCueStyleRawValue)
    }
}

private final class GameSceneDelegateImpl: GameSceneDelegate {
    let onScoreUpdate: (Int) -> Void
    let onCollision: () -> Void
    let onPauseStateChange: (Bool) -> Void

    init(onScoreUpdate: @escaping (Int) -> Void, onCollision: @escaping () -> Void, onPauseStateChange: @escaping (Bool) -> Void = { _ in }) {
        self.onScoreUpdate = onScoreUpdate
        self.onCollision = onCollision
        self.onPauseStateChange = onPauseStateChange
    }

    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int) {
        onScoreUpdate(score)
    }

    func gameSceneDidDetectCollision(_ gameScene: GameScene) {
        onCollision()
    }

    func gameSceneDidUpdateGrid(_ gameScene: GameScene) {}

    func gameScene(_ gameScene: GameScene, didUpdatePauseState isPaused: Bool) {
        onPauseStateChange(isPaused)
    }

    func gameScene(_ gameScene: GameScene, didAchieveNewHighScore score: Int) {
        // Watch high score handled in the view; no-op.
    }
}
