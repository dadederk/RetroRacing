import SwiftUI
import SpriteKit
import RetroRacingShared

struct tvOSGameView: View {
    private static let sharedBundle = Bundle(for: GameScene.self)

    let leaderboardService: LeaderboardService
    let ratingService: RatingService

    @State private var scene: GameScene
    @State private var score: Int = 0
    @State private var lives: Int = 3
    @State private var showGameOver = false
    @State private var gameOverScore: Int = 0
    @State private var delegate: GameSceneDelegateImpl?
    @Environment(\.dismiss) private var dismiss

    init(leaderboardService: LeaderboardService, ratingService: RatingService) {
        self.leaderboardService = leaderboardService
        self.ratingService = ratingService
        let size = CGSize(width: 1920, height: 1080)
        _scene = State(initialValue: GameScene.scene(size: size, theme: nil, imageLoader: UIKitImageLoader()))
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
                    .font(.custom("PressStart2P-Regular", size: 28))
                Spacer()
                HStack(spacing: 8) {
                    Image(LCDTheme().lifeSprite() ?? "life", bundle: Self.sharedBundle)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 28, height: 28)
                    Text(" x\(lives)")
                        .font(.custom("PressStart2P-Regular", size: 28))
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
                    }
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

    init(onScoreUpdate: @escaping (Int) -> Void, onCollision: @escaping () -> Void) {
        self.onScoreUpdate = onScoreUpdate
        self.onCollision = onCollision
    }

    func gameScene(_ gameScene: GameScene, didUpdateScore score: Int) {
        onScoreUpdate(score)
    }

    func gameSceneDidDetectCollision(_ gameScene: GameScene) {
        onCollision()
    }
}
