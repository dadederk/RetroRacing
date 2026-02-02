import SwiftUI
import SpriteKit
import RetroRacingShared

struct WatchGameView: View {
    @State private var scene: GameScene
    @State private var rotationValue: Double = 0
    @State private var score: Int = 0
    @State private var lives: Int = 3
    @State private var showGameOver = false
    @State private var gameOverScore: Int = 0
    @State private var delegate: GameSceneDelegateImpl?
    @Environment(\.dismiss) private var dismiss

    init() {
        let size = CGSize(width: 400, height: 300)
        _scene = State(initialValue: GameScene.scene(size: size, theme: GameBoyTheme(), imageLoader: UIKitImageLoader()))
    }

    private static let sharedBundle = Bundle(for: GameScene.self)

    private static let crownMoveThreshold: Double = 4

    var body: some View {
        VStack {
            HStack {
                Text(GameLocalizedStrings.format("score %lld", score))
                    .font(.custom("PressStart2P-Regular", size: 10))
                Spacer()
                HStack(spacing: 2) {
                    Image(GameBoyTheme().lifeSprite() ?? "life", bundle: Self.sharedBundle)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                    Text(" x\(lives)")
                        .font(.custom("PressStart2P-Regular", size: 10))
                }
            }
            GeometryReader { geo in
                ZStack {
                    SpriteView(scene: scene)
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture(coordinateSpace: .local) { location in
                            if location.x < geo.size.width / 2 {
                                scene.moveLeft()
                            } else {
                                scene.moveRight()
                            }
                        }
                }
                .focusable()
                .digitalCrownRotation($rotationValue, from: 0, through: 100, by: 1, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: true)
                .onChange(of: rotationValue, initial: false) { oldValue, newValue in
                    let delta = newValue - oldValue
                    if delta >= Self.crownMoveThreshold {
                        scene.moveRight()
                    } else if delta <= -Self.crownMoveThreshold {
                        scene.moveLeft()
                    }
                }
            }
        }
        .onAppear {
            scene.start()
            score = scene.gameState.score
            lives = scene.gameState.lives
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
                    }
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
