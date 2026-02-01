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
        _scene = State(initialValue: GameScene.scene(size: size))
    }

    private static let sharedBundle = Bundle(for: GameScene.self)

    var body: some View {
        VStack {
            HStack {
                Text(String(format: String(localized: "score %lld"), score))
                    .font(.custom("PressStart2P-Regular", size: 10))
                Spacer()
                HStack(spacing: 2) {
                    Image("life", bundle: Self.sharedBundle)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 16, height: 16)
                    Text("\(lives)")
                        .font(.custom("PressStart2P-Regular", size: 10))
                }
            }
            SpriteView(scene: scene)
                .focusable()
                .digitalCrownRotation($rotationValue, from: 0, through: 100, by: 1, sensitivity: .low, isContinuous: true, isHapticFeedbackEnabled: true)
                .onChange(of: rotationValue, initial: false) { oldValue, newValue in
                    if newValue > oldValue {
                        scene.moveRight()
                    } else if newValue < oldValue {
                        scene.moveLeft()
                    }
                }
        }
        .onAppear {
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
            score = scene.gameState.score
            lives = scene.gameState.lives
        }
        .alert(String(localized: "gameOver"), isPresented: $showGameOver) {
            Button(String(localized: "restart")) {
                scene.start()
                score = scene.gameState.score
                lives = scene.gameState.lives
                showGameOver = false
            }
            Button(String(localized: "finish")) {
                dismiss()
            }
        } message: {
            Text(String(format: String(localized: "score %lld"), gameOverScore))
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
