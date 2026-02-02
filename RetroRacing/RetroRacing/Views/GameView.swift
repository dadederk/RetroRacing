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
    #if os(macOS) || os(iOS)
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @FocusState private var isGameAreaFocused: Bool
    #endif

    init(leaderboardService: LeaderboardService, ratingService: RatingService, theme: (any GameTheme)? = nil) {
        self.leaderboardService = leaderboardService
        self.ratingService = ratingService
        self.theme = theme
    }

    private static func makeScene(side: CGFloat, theme: (any GameTheme)?) -> GameScene {
        #if os(macOS)
        let loader = AppKitImageLoader()
        #else
        let loader = UIKitImageLoader()
        #endif
        return GameScene.scene(size: CGSize(width: side, height: side), theme: theme, imageLoader: loader)
    }

    /// Pure: returns current score and lives from a scene (no side effects).
    private static func scoreAndLives(from scene: GameScene) -> (score: Int, lives: Int) {
        (scene.gameState.score, scene.gameState.lives)
    }

    /// Uses size classes when available (iPad split screen, multi-window); falls back to size comparison (e.g. macOS).
    private func useLandscapeLayout(containerSize: CGSize) -> Bool {
        #if os(macOS) || os(iOS)
        switch (horizontalSizeClass, verticalSizeClass) {
        case (.regular, _): return true   // Wide: use side-by-side layout (e.g. iPad, split view)
        case (_, .compact): return true    // Short: use side-by-side (e.g. landscape, slide over)
        case (.compact, .regular): return false  // Tall and narrow: use stacked layout (e.g. phone portrait)
        default: return containerSize.width > containerSize.height  // Fallback when size classes unavailable
        }
        #else
        return containerSize.width > containerSize.height
        #endif
    }

    private func headerScoreLabel() -> some View {
        Text(GameLocalizedStrings.format("score %lld", score))
            .font(.custom("PressStart2P-Regular", size: 14))
            .foregroundStyle(.white)
            .shadow(color: .black, radius: 1)
            .accessibilityLabel(GameLocalizedStrings.format("score %lld", score))
    }

    private func headerLivesView() -> some View {
        let lifeAsset = theme?.lifeSprite() ?? "life"
        return HStack(spacing: 4) {
            Image(lifeAsset, bundle: Self.sharedBundle)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 20, height: 20)
            Text(" x\(lives)")
                .font(.custom("PressStart2P-Regular", size: 14))
                .foregroundStyle(.white)
                .shadow(color: .black, radius: 1)
                .accessibilityLabel(GameLocalizedStrings.format("%lld lives remaining", lives))
        }
    }

    @ViewBuilder
    private func portraitLayout(containerSize: CGSize) -> some View {
        VStack(spacing: 0) {
            Spacer()
            HStack {
                headerScoreLabel()
                Spacer()
                headerLivesView()
            }
            .padding()
            gameAreaWithFullScreenTouch()
            Spacer()
        }
    }

    @ViewBuilder
    private func landscapeLayout(containerSize: CGSize) -> some View {
        HStack(spacing: 0) {
            VStack {
                headerScoreLabel()
                Spacer()
            }
            .padding()
            gameAreaWithFullScreenTouch()
                .frame(maxWidth: .infinity)
            VStack {
                headerLivesView()
                Spacer()
            }
            .padding()
        }
    }

    @ViewBuilder
    private func gameAreaWithFullScreenTouch() -> some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            gameAreaContent(side: side)
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                #if os(macOS) || os(iOS)
                .focusable()
                .focused($isGameAreaFocused)
                #endif
                .modifier(GameAreaKeyboardModifier(scene: scene))
                .onAppear {
                    setFocusForGameArea()
                    setupSceneAndDelegateIfNeeded(side: side)
                }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func gameAreaContent(side: CGFloat) -> some View {
        if let scene = scene {
            SpriteView(scene: scene)
                .frame(width: side, height: side)
        } else {
            Color(red: 202/255, green: 220/255, blue: 159/255)
                .frame(width: side, height: side)
        }
    }

    #if os(macOS) || os(iOS)
    private func setFocusForGameArea() {
        isGameAreaFocused = true
    }
    #else
    private func setFocusForGameArea() {}
    #endif

    private func setupSceneAndDelegateIfNeeded(side: CGFloat) {
        if scene == nil, side > 0 {
            createSceneAndDelegate(side: side)
        } else if let gameScene = scene, delegate == nil {
            attachDelegate(to: gameScene)
        } else if let gameScene = scene {
            syncScoreAndLivesFromScene(gameScene)
        }
    }

    private func createSceneAndDelegate(side: CGFloat) {
        let newScene = Self.makeScene(side: side, theme: theme)
        scene = newScene
        let newDelegate = makeGameSceneDelegate()
        delegate = newDelegate
        newScene.gameDelegate = newDelegate
        let (currentScore, currentLives) = Self.scoreAndLives(from: newScene)
        score = currentScore
        lives = currentLives
    }

    private func attachDelegate(to gameScene: GameScene) {
        let newDelegate = makeGameSceneDelegate()
        delegate = newDelegate
        gameScene.gameDelegate = newDelegate
        let (currentScore, currentLives) = Self.scoreAndLives(from: gameScene)
        score = currentScore
        lives = currentLives
    }

    private func syncScoreAndLivesFromScene(_ gameScene: GameScene) {
        let (currentScore, currentLives) = Self.scoreAndLives(from: gameScene)
        score = currentScore
        lives = currentLives
    }

    private func makeGameSceneDelegate() -> GameSceneDelegateImpl {
        GameSceneDelegateImpl(
            onScoreUpdate: { score = $0 },
            onCollision: handleCollision
        )
    }

    private func handleCollision() {
        guard let scene = scene else { return }
        let (currentScore, currentLives) = Self.scoreAndLives(from: scene)
        lives = currentLives
        if currentLives == 0 {
            leaderboardService.submitScore(currentScore)
            ratingService.checkAndRequestRating(score: currentScore)
            gameOverScore = currentScore
            showGameOver = true
        } else {
            scene.resume()
        }
    }

    var body: some View {
        GeometryReader { outer in
            ZStack {
                if useLandscapeLayout(containerSize: outer.size) {
                    landscapeLayout(containerSize: outer.size)
                } else {
                    portraitLayout(containerSize: outer.size)
                }
                // Full-screen touch overlay: left/right by container width so taps work anywhere on screen.
                Color.clear
                    .contentShape(Rectangle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .onTapGesture(coordinateSpace: .local) { location in
                        guard let scene = scene else { return }
                        if location.x < outer.size.width / 2 {
                            scene.moveLeft()
                        } else {
                            scene.moveRight()
                        }
                    }
                    .gesture(
                        DragGesture(minimumDistance: 20)
                            .onEnded { value in
                                guard let scene = scene else { return }
                                if value.translation.width < 0 { scene.moveLeft() }
                                else if value.translation.width > 0 { scene.moveRight() }
                            }
                    )
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .alert(GameLocalizedStrings.string("gameOver"), isPresented: $showGameOver) {
            Button(GameLocalizedStrings.string("restart")) {
                scene?.start()
                if let scene = scene {
                    let (currentScore, currentLives) = Self.scoreAndLives(from: scene)
                    score = currentScore
                    lives = currentLives
                }
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

private extension Notification.Name {
    static let gameSceneScoreDidUpdate = Notification.Name("GameSceneScoreDidUpdate")
}

