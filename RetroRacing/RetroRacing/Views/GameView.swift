import SwiftUI
import SpriteKit
import RetroRacingShared

struct GameView: View {
    private static let sharedBundle = Bundle(for: GameScene.self)

    let leaderboardService: LeaderboardService
    let ratingService: RatingService
    let theme: (any GameTheme)?

    @State private var scene: GameScene?
    @State private var score: Int = 0
    @State private var lives: Int = 3
    @State private var showGameOver = false
    @State private var gameOverScore: Int = 0
    @State private var delegate: GameSceneDelegateImpl?
    @Environment(\.dismiss) private var dismiss
    #if os(macOS)
    @FocusState private var isGameAreaFocused: Bool
    #endif

    init(leaderboardService: LeaderboardService, ratingService: RatingService, theme: (any GameTheme)? = nil) {
        self.leaderboardService = leaderboardService
        self.ratingService = ratingService
        self.theme = theme
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text(String(format: String(localized: "score %lld"), score))
                    .font(.custom("PressStart2P-Regular", size: 14))
                    .foregroundStyle(.white)
                    .shadow(color: .black, radius: 1)
                    .accessibilityLabel(String(format: String(localized: "score %lld"), score))
                Spacer()
                HStack(spacing: 4) {
                    Image("life", bundle: Self.sharedBundle)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 20, height: 20)
                    Text("\(lives)")
                        .font(.custom("PressStart2P-Regular", size: 14))
                        .foregroundStyle(.white)
                        .shadow(color: .black, radius: 1)
                        .accessibilityLabel(String(format: String(localized: "%lld lives remaining"), lives))
                }
            }
            .padding()

            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                ZStack {
                    if let scene = scene {
                        SpriteView(scene: scene)
                            .frame(width: side, height: side)
                        Color.clear
                            .contentShape(Rectangle())
                            .frame(width: side, height: side)
                            .gesture(
                                DragGesture(minimumDistance: 20)
                                    .onEnded { value in
                                        if value.translation.width < 0 { scene.moveLeft() }
                                        else if value.translation.width > 0 { scene.moveRight() }
                                    }
                            )
                            .onTapGesture(coordinateSpace: .local) { location in
                                if location.x < side / 2 {
                                    scene.moveLeft()
                                } else {
                                    scene.moveRight()
                                }
                            }
                    } else {
                        Color(red: 202/255, green: 220/255, blue: 159/255)
                            .frame(width: side, height: side)
                    }
                }
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                #if os(macOS)
                .focusable()
                .focused($isGameAreaFocused)
                .onKeyPress(.leftArrow) {
                    scene?.moveLeft()
                    return .handled
                }
                .onKeyPress(.rightArrow) {
                    scene?.moveRight()
                    return .handled
                }
                #endif
                .onAppear {
                    #if os(macOS)
                    isGameAreaFocused = true
                    #endif
                    if scene == nil, side > 0 {
                        let s = GameScene.scene(size: CGSize(width: side, height: side), theme: theme)
                        scene = s
                        let d = GameSceneDelegateImpl(
                            onScoreUpdate: { score = $0 },
                            onCollision: {
                                guard let scene = scene else { return }
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
                        s.gameDelegate = d
                        score = s.gameState.score
                        lives = s.gameState.lives
                    } else if let gameScene = scene, delegate == nil {
                        let d = GameSceneDelegateImpl(
                            onScoreUpdate: { score = $0 },
                            onCollision: {
                                guard let scene = scene else { return }
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
                        gameScene.gameDelegate = d
                        score = gameScene.gameState.score
                        lives = gameScene.gameState.lives
                    } else if let gameScene = scene {
                        score = gameScene.gameState.score
                        lives = gameScene.gameState.lives
                    }
                }
            }
            .aspectRatio(1, contentMode: .fit)
        }
        .alert(String(localized: "gameOver"), isPresented: $showGameOver) {
            Button(String(localized: "restart")) {
                scene?.start()
                if let scene = scene {
                    score = scene.gameState.score
                    lives = scene.gameState.lives
                }
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

private extension Notification.Name {
    static let gameSceneScoreDidUpdate = Notification.Name("GameSceneScoreDidUpdate")
}


