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

    @State private var scene: GameScene
    @State private var score: Int = 0
    @State private var lives: Int = 3
    @State private var showGameOver = false
    @State private var gameOverScore: Int = 0
    @State private var delegate: GameSceneDelegateImpl?
    @Environment(\.dismiss) private var dismiss

    init(leaderboardService: LeaderboardService, ratingService: RatingService, theme: (any GameTheme)? = nil, hapticController: HapticFeedbackController? = nil, fontPreferenceStore: FontPreferenceStore? = nil) {
        self.leaderboardService = leaderboardService
        self.ratingService = ratingService
        self.theme = theme
        self.hapticController = hapticController
        self.fontPreferenceStore = fontPreferenceStore
        let size = CGSize(width: 1920, height: 1080)
        _scene = State(initialValue: GameScene.scene(size: size, theme: theme, imageLoader: UIKitImageLoader()))
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
                    .onTapGesture { scene.moveLeft() }
                    .frame(maxWidth: .infinity)
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture { scene.moveRight() }
                    .frame(maxWidth: .infinity)
            }

            HStack {
                Text(GameLocalizedStrings.format("score %lld", score))
                    .font(headerFont(size: 28))
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
            }
            Button(GameLocalizedStrings.string("finish")) {
                dismiss()
            }
        } message: {
            Text(GameLocalizedStrings.format("score %lld", gameOverScore))
        }
        .onAppear {
            if delegate == nil {
                let d = GameSceneDelegateImpl(
                    onScoreUpdate: { score = $0 },
                    onCollision: {
                        lives = scene.gameState.lives
                        if scene.gameState.lives == 0 {
                            let finalScore = scene.gameState.score
                            leaderboardService.submitScore(finalScore)
                            ratingService.checkAndRequestRating(score: finalScore)
                            gameOverScore = finalScore
                            showGameOver = true
                        } else {
                            scene.resume()
                        }
                    },
                    hapticController: hapticController
                )
                delegate = d
                scene.gameDelegate = d
            }
            score = scene.gameState.score
            lives = scene.gameState.lives
        }
    }
}

private final class GameSceneDelegateImpl: GameSceneDelegate {
    let onScoreUpdate: (Int) -> Void
    let onCollision: () -> Void
    let hapticController: HapticFeedbackController?

    init(onScoreUpdate: @escaping (Int) -> Void, onCollision: @escaping () -> Void, hapticController: HapticFeedbackController? = nil) {
        self.onScoreUpdate = onScoreUpdate
        self.onCollision = onCollision
        self.hapticController = hapticController
    }

    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int) {
        onScoreUpdate(score)
    }

    func gameSceneDidDetectCollision(_ gameScene: GameScene) {
        hapticController?.triggerCrashHaptic()
        onCollision()
    }

    func gameSceneDidUpdateGrid(_ gameScene: GameScene) {
        hapticController?.triggerGridUpdateHaptic()
    }
}
