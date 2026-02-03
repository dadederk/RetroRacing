import SwiftUI
import SpriteKit
import RetroRacingShared

struct WatchGameView: View {
    let theme: any GameTheme
    let fontPreferenceStore: FontPreferenceStore?
    @AppStorage(SoundPreferences.volumeKey) private var sfxVolume: Double = SoundPreferences.defaultVolume
    @State private var scene: GameScene
    @State private var rotationValue: Double = 0
    @State private var score: Int = 0
    @State private var lives: Int = 3
    @State private var scenePaused: Bool = false
    @State private var isUserPaused: Bool = false
    @State private var showGameOver = false
    @State private var gameOverScore: Int = 0
    @State private var delegate: GameSceneDelegateImpl?
    @State private var inputAdapter: GameInputAdapter?
    @Environment(\.dismiss) private var dismiss

    private var pauseButtonDisabled: Bool {
        scenePaused && isUserPaused == false
    }

    init(theme: any GameTheme, fontPreferenceStore: FontPreferenceStore? = nil) {
        self.theme = theme
        self.fontPreferenceStore = fontPreferenceStore
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
    }

    private func headerFont(size: CGFloat = 10) -> Font {
        fontPreferenceStore?.font(size: size) ?? .custom("PressStart2P-Regular", size: size)
    }

    private static let sharedBundle = Bundle(for: GameScene.self)

    private static let crownMoveThreshold: Double = 4

    var body: some View {
        VStack {
            HStack {
                Text(GameLocalizedStrings.format("score %lld", score))
                    .font(headerFont(size: 10))
                Spacer()
                Button {
                    togglePause()
                } label: {
                    Image(systemName: isUserPaused ? "play.fill" : "pause.fill")
                }
                .accessibilityLabel(GameLocalizedStrings.string(isUserPaused ? "resume" : "pause"))
                .disabled(pauseButtonDisabled)
                .opacity(pauseButtonDisabled ? 0.4 : 1)
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
                .digitalCrownRotation($rotationValue, from: 0, through: 100, by: 1, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: true)
                .onChange(of: rotationValue, initial: false) { oldValue, newValue in
                    let delta = newValue - oldValue
                    if delta >= Self.crownMoveThreshold {
                        inputAdapter?.handleRight()
                    } else if delta <= -Self.crownMoveThreshold {
                        inputAdapter?.handleLeft()
                    }
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
            }
            Button(GameLocalizedStrings.string("finish")) {
                dismiss()
            }
        } message: {
            Text(GameLocalizedStrings.format("score %lld", gameOverScore))
        }
        .onDisappear {
            scene.stopAllSounds()
        }
        .onChange(of: sfxVolume) { _, newValue in
            scene.setSoundVolume(newValue)
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
}
