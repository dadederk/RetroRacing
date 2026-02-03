import SwiftUI
import SpriteKit
import RetroRacingShared

struct WatchGameView: View {
    let theme: any GameTheme
    let fontPreferenceStore: FontPreferenceStore?
    let highestScoreStore: HighestScoreStore
    let crownConfiguration: LegacyCrownInputProcessor.Configuration
    @AppStorage(SoundPreferences.volumeKey) private var sfxVolume: Double = SoundPreferences.defaultVolume
    @State private var scene: GameScene
    @State private var rotationValue: Double = 0
    @State private var crownProcessor: LegacyCrownInputProcessor
    @State private var crownIdleTask: Task<Void, Never>?
    @State private var score: Int = 0
    @State private var lives: Int = 3
    @State private var scenePaused: Bool = false
    @State private var isUserPaused: Bool = false
    @State private var showGameOver = false
    @State private var gameOverScore: Int = 0
    @State private var isNewHighScore = false
    @State private var delegate: GameSceneDelegateImpl?
    @State private var inputAdapter: GameInputAdapter?
    @Environment(\.dismiss) private var dismiss

    private var pauseButtonDisabled: Bool {
        scenePaused && isUserPaused == false
    }

    init(
        theme: any GameTheme,
        fontPreferenceStore: FontPreferenceStore? = nil,
        highestScoreStore: HighestScoreStore,
        crownConfiguration: LegacyCrownInputProcessor.Configuration
    ) {
        self.theme = theme
        self.fontPreferenceStore = fontPreferenceStore
        self.highestScoreStore = highestScoreStore
        self.crownConfiguration = crownConfiguration
        let size = CGSize(width: 400, height: 300)
        let soundPlayer = PlatformFactories.makeSoundPlayer()
        soundPlayer.setVolume(SoundPreferences.defaultVolume)
        _scene = State(initialValue: GameScene.scene(
            size: size,
            theme: theme,
            imageLoader: PlatformFactories.makeImageLoader(),
            soundPlayer: soundPlayer,
            hapticController: nil
        ))
        _crownProcessor = State(initialValue: LegacyCrownInputProcessor(configuration: crownConfiguration))
    }

    private func headerFont(size: CGFloat = 10) -> Font {
        fontPreferenceStore?.font(size: size) ?? .custom("PressStart2P-Regular", size: size)
    }

    private static let sharedBundle = Bundle(for: GameScene.self)

    private static let crownIdleResetDelay: Duration = .milliseconds(150)

    var body: some View {
        VStack {
            HStack {
                Text(GameLocalizedStrings.format("score %lld", score))
                    .font(headerFont(size: 10))
                Spacer()
                HStack(spacing: 2) {
                    Image(theme.lifeSprite() ?? "life", bundle: Self.sharedBundle)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                    Text(GameLocalizedStrings.format("lives_count", lives))
                        .font(headerFont(size: 10))
                }
            }
            GeometryReader { geo in
                ZStack {
                    SpriteView(scene: scene)
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(coordinateSpace: .local) { location in
                            if location.x < geo.size.width / 2 {
                                inputAdapter?.handleLeft()
                            } else {
                                inputAdapter?.handleRight()
                            }
                        }
                }
                .focusable()
                .digitalCrownRotation(
                    $rotationValue,
                    from: -10,
                    through: 10,
                    by: 0.1,
                    sensitivity: .high,
                    isContinuous: true,
                    isHapticFeedbackEnabled: true
                )
                .onChange(of: rotationValue, initial: false) { oldValue, newValue in
                    handleCrownDelta(newValue - oldValue)
                    rotationValue = 0
                }
            }
        }
        .onAppear {
            scene.setSoundVolume(sfxVolume)
            scene.start()
            score = scene.gameState.score
            lives = scene.gameState.lives
            scenePaused = scene.gameState.isPaused
            inputAdapter = CrownGameInputAdapter(controller: scene)
            if delegate == nil {
                let d = GameSceneDelegateImpl(
                    onScoreUpdate: { score = $0 },
                    onCollision: {
                        lives = scene.gameState.lives
                        if scene.gameState.lives == 0 {
                            gameOverScore = scene.gameState.score
                            isNewHighScore = highestScoreStore.updateIfHigher(gameOverScore)
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
        .alert(GameLocalizedStrings.string("gameOver"), isPresented: $showGameOver) {
            Button(GameLocalizedStrings.string("restart")) {
                scene.start()
                score = scene.gameState.score
                lives = scene.gameState.lives
                showGameOver = false
                isNewHighScore = false
            }
            Button(GameLocalizedStrings.string("finish")) {
                dismiss()
            }
        } message: {
            if isNewHighScore {
                Text(GameLocalizedStrings.format("new_high_score_message %lld", gameOverScore))
            } else {
                Text(GameLocalizedStrings.format("score %lld", gameOverScore))
            }
        }
        .onDisappear {
            scene.stopAllSounds()
            crownIdleTask?.cancel()
            crownIdleTask = nil
        }
        .onChange(of: sfxVolume) { _, newValue in
            scene.setSoundVolume(newValue)
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

    private func handleCrownDelta(_ delta: Double) {
        let action = crownProcessor.handleRotationDelta(delta)
        scheduleCrownIdleReset()

        switch action {
        case .moveLeft:
            inputAdapter?.handleLeft()
        case .moveRight:
            inputAdapter?.handleRight()
        case .none:
            break
        }
    }

    private func scheduleCrownIdleReset() {
        crownIdleTask?.cancel()
        crownIdleTask = Task { @MainActor in
            try? await Task.sleep(for: Self.crownIdleResetDelay)
            guard Task.isCancelled == false else { return }
            crownProcessor.markIdle()
        }
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
