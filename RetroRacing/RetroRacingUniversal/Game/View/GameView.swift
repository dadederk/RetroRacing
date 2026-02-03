import SwiftUI
import SpriteKit
import RetroRacingShared

struct GameView: View {
    static let sharedBundle = Bundle(for: GameScene.self)

    let leaderboardService: LeaderboardService
    let ratingService: RatingService
    let theme: (any GameTheme)?
    let hapticController: HapticFeedbackController?
    let fontPreferenceStore: FontPreferenceStore?

    @State var scene: GameScene?
    @State var score: Int = 0
    @State var lives: Int = 3
    @State var showGameOver = false
    @State var gameOverScore: Int = 0
    @State var delegate: GameSceneDelegateImpl?
    @State var leftButtonDown = false
    @State var rightButtonDown = false
    @ScaledMetric(relativeTo: .body) var directionButtonHeight: CGFloat = 120
    @Environment(\.dismiss) var dismiss
    #if os(macOS) || os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @FocusState var isGameAreaFocused: Bool
    #endif

    init(leaderboardService: LeaderboardService, ratingService: RatingService, theme: (any GameTheme)? = nil, hapticController: HapticFeedbackController? = nil, fontPreferenceStore: FontPreferenceStore? = nil) {
        self.leaderboardService = leaderboardService
        self.ratingService = ratingService
        self.theme = theme
        self.hapticController = hapticController
        self.fontPreferenceStore = fontPreferenceStore
    }

    @ViewBuilder
    func gameAreaWithFullScreenTouch() -> some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            gameAreaContent(side: side)
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .modifier(GameAreaKeyboardModifier(scene: scene, onMoveLeft: { flashButton(.left) }, onMoveRight: { flashButton(.right) }))
                .onAppear {
                    setFocusForGameArea()
                    setupSceneAndDelegateIfNeeded(side: side)
                }
        }
        .aspectRatio(1, contentMode: .fit)
    }

    var body: some View {
        GeometryReader { outer in
            ZStack {
                if useLandscapeLayout(containerSize: outer.size) {
                    landscapeLayout(containerSize: outer.size)
                } else {
                    portraitLayout(containerSize: outer.size)
                }
                // Left/right touch areas: taps and VoiceOver double-tap trigger move. Drag on full width.
                HStack(spacing: 0) {
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            guard let scene = scene else { return }
                            flashButton(.left)
                            scene.moveLeft()
                        }
                        .accessibilityLabel(GameLocalizedStrings.string("move_left"))
                        .accessibilityHint(GameLocalizedStrings.string("move_left_hint"))
                        .accessibilityAddTraits(.isButton)
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            guard let scene = scene else { return }
                            flashButton(.right)
                            scene.moveRight()
                        }
                        .accessibilityLabel(GameLocalizedStrings.string("move_right"))
                        .accessibilityHint(GameLocalizedStrings.string("move_right_hint"))
                        .accessibilityAddTraits(.isButton)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            guard let scene = scene else { return }
                            if value.translation.width < 0 {
                                flashButton(.left)
                                scene.moveLeft()
                            } else if value.translation.width > 0 {
                                flashButton(.right)
                                scene.moveRight()
                            }
                        }
                )
            }
        }
        #if os(macOS) || os(iOS)
        .focusable()
        .focused($isGameAreaFocused)
        .onKeyPress(.leftArrow) {
            guard let scene = scene else { return .ignored }
            flashButton(.left)
            scene.moveLeft()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            guard let scene = scene else { return .ignored }
            flashButton(.right)
            scene.moveRight()
            return .handled
        }
        #endif
        .ignoresSafeArea(edges: .bottom)
        #if os(iOS)
        .persistentSystemOverlays(.hidden)
        #endif
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

    private enum ButtonSide { case left, right }

    private func flashButton(_ side: ButtonSide) {
        withAnimation(.easeOut(duration: 0.05)) {
            switch side {
            case .left: leftButtonDown = true
            case .right: rightButtonDown = true
            }
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 150_000_000)
            withAnimation(.easeOut(duration: 0.05)) {
                switch side {
                case .left: leftButtonDown = false
                case .right: rightButtonDown = false
                }
            }
        }
    }
}

private extension Notification.Name {
    static let gameSceneScoreDidUpdate = Notification.Name("GameSceneScoreDidUpdate")
}

