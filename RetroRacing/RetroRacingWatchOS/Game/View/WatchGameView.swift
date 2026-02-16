import SwiftUI
import SpriteKit
import RetroRacingShared

struct WatchGameView: View {
    let theme: any GameTheme
    let fontPreferenceStore: FontPreferenceStore?
    let highestScoreStore: HighestScoreStore
    let crownConfiguration: LegacyCrownInputProcessor.Configuration
    let leaderboardService: LeaderboardService
    @AppStorage(GameDifficulty.storageKey) private var selectedDifficultyRawValue: String = GameDifficulty.defaultDifficulty.rawValue
    @AppStorage(SoundPreferences.volumeKey) private var sfxVolume: Double = SoundPreferences.defaultVolume
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
    @FocusState private var isCrownFocused: Bool
    @Environment(\.dismiss) private var dismiss

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
        let size = CGSize(width: 400, height: 300)
        let soundPlayer = PlatformFactories.makeSoundPlayer()
        soundPlayer.setVolume(SoundPreferences.defaultVolume)
        _scene = State(initialValue: GameScene.scene(
            size: size,
            difficulty: initialDifficulty,
            theme: theme,
            imageLoader: PlatformFactories.makeImageLoader(),
            soundPlayer: soundPlayer,
            hapticController: nil
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
                    sensitivity: .high,
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
        }
        .sheet(isPresented: $showGameOver) {
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
        }
        .onDisappear {
            scene.stopAllSounds()
            crownIdleTask?.cancel()
            crownIdleTask = nil
        }
        .onChange(of: sfxVolume) { _, newValue in
            scene.setSoundVolume(newValue)
        }
        .onChange(of: selectedDifficultyRawValue) { _, _ in
            scene.applyDifficulty(selectedDifficulty)
        }
        .toolbar {
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
        GameDifficulty.fromStoredValue(selectedDifficultyRawValue)
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
