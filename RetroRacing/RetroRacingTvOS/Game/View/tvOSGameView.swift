import SwiftUI
import SpriteKit
import RetroRacingShared

struct tvOSGameView: View {
    private static let sharedBundle = Bundle(for: GameScene.self)

    let leaderboardService: LeaderboardService
    let ratingService: RatingService
    let theme: (any GameTheme)?
    let hapticController: HapticFeedbackController?
    let fontPreferenceStore: FontPreferenceStore?
    let highestScoreStore: HighestScoreStore

    @AppStorage(SoundPreferences.volumeKey) private var sfxVolume: Double = SoundPreferences.defaultVolume
    @State private var scene: GameScene
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

    init(leaderboardService: LeaderboardService, ratingService: RatingService, theme: (any GameTheme)? = nil, hapticController: HapticFeedbackController? = nil, fontPreferenceStore: FontPreferenceStore? = nil, highestScoreStore: HighestScoreStore) {
        self.leaderboardService = leaderboardService
        self.ratingService = ratingService
        self.theme = theme
        self.hapticController = hapticController
        self.fontPreferenceStore = fontPreferenceStore
        self.highestScoreStore = highestScoreStore
        let size = CGSize(width: 1920, height: 1080)
        let soundPlayer = PlatformFactories.makeSoundPlayer()
        soundPlayer.setVolume(SoundPreferences.defaultVolume)
        _scene = State(initialValue: GameScene.scene(
            size: size,
            theme: theme,
            imageLoader: PlatformFactories.makeImageLoader(),
            soundPlayer: soundPlayer,
            hapticController: hapticController
        ))
    }

    private func headerFont(size: CGFloat = 28) -> Font {
        fontPreferenceStore?.font(size: size) ?? .custom("PressStart2P-Regular", size: size)
    }

    var body: some View {
        ZStack(alignment: .top) {
            SpriteView(scene: scene)
                .ignoresSafeArea()
            HStack(spacing: 0) {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { inputAdapter?.handleLeft() }
                    .frame(maxWidth: .infinity)
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { inputAdapter?.handleRight() }
                    .frame(maxWidth: .infinity)
            }

            HStack {
                Text(GameLocalizedStrings.format("score %lld", score))
                    .font(headerFont(size: 28))
                Spacer()
                Button {
                    togglePause()
                } label: {
                    Label(
                        GameLocalizedStrings.string(isUserPaused ? "resume" : "pause"),
                        systemImage: isUserPaused ? "play.fill" : "pause.fill"
                    )
                    .font(headerFont(size: 22))
                }
                .buttonStyle(.borderedProminent)
                .labelStyle(.titleAndIcon)
                .accessibilityLabel(GameLocalizedStrings.string(isUserPaused ? "resume" : "pause"))
                .disabled(pauseButtonDisabled)
                .opacity(pauseButtonDisabled ? 0.4 : 1)
                Spacer()
                HStack(spacing: 8) {
                    Image(theme?.lifeSprite() ?? "life", bundle: Self.sharedBundle)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                    Text(GameLocalizedStrings.format("lives_count", lives))
                        .font(headerFont(size: 28))
                }
            }
            .padding(60)
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
        }
        .onChange(of: sfxVolume) { _, newValue in
            scene.setSoundVolume(newValue)
        }
        .onPlayPauseCommand(perform: togglePause)
        .onAppear {
            scene.setSoundVolume(sfxVolume)
            if delegate == nil {
                let d = GameSceneDelegateImpl(
                    onScoreUpdate: { score = $0 },
                    onCollision: {
                        lives = scene.gameState.lives
                        if scene.gameState.lives == 0 {
                            let finalScore = scene.gameState.score
                            leaderboardService.submitScore(finalScore)
                            ratingService.checkAndRequestRating(score: finalScore)
                            isNewHighScore = highestScoreStore.updateIfHigher(finalScore)
                            if isNewHighScore {
                                hapticController?.triggerSuccessHaptic()
                            }
                            gameOverScore = finalScore
                            showGameOver = true
                        } else {
                            scene.resume()
                        }
                    },
                    onPauseStateChange: { newPaused in
                        scenePaused = newPaused
                        if !isUserPaused { isUserPaused = false }
                    },
                    hapticController: hapticController
                )
                delegate = d
                scene.gameDelegate = d
            }
            inputAdapter = RemoteGameInputAdapter(controller: scene, hapticController: hapticController)
            score = scene.gameState.score
            lives = scene.gameState.lives
            scenePaused = scene.gameState.isPaused
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
    let hapticController: HapticFeedbackController?
    let onPauseStateChange: (Bool) -> Void

    init(
        onScoreUpdate: @escaping (Int) -> Void,
        onCollision: @escaping () -> Void,
        onPauseStateChange: @escaping (Bool) -> Void = { _ in },
        hapticController: HapticFeedbackController? = nil
    ) {
        self.onScoreUpdate = onScoreUpdate
        self.onCollision = onCollision
        self.onPauseStateChange = onPauseStateChange
        self.hapticController = hapticController
    }

    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int) {
        onScoreUpdate(score)
    }

    func gameSceneDidDetectCollision(_ gameScene: GameScene) {
        onCollision()
    }

    func gameSceneDidUpdateGrid(_ gameScene: GameScene) {
        hapticController?.triggerGridUpdateHaptic()
    }

    func gameScene(_ gameScene: GameScene, didUpdatePauseState isPaused: Bool) {
        onPauseStateChange(isPaused)
    }

    func gameScene(_ gameScene: GameScene, didAchieveNewHighScore score: Int) {
        // High score handling lives in the view; no-op.
    }
}
