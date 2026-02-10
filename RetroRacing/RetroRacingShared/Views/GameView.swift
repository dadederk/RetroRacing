//
//  GameView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI
import SpriteKit

/// SwiftUI game screen that hosts the shared SpriteKit scene and routes platform input.
@MainActor
public struct GameView: View {
    static let sharedBundle = Bundle(for: GameScene.self)
    private static var menuToolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .navigation
        #else
        .topBarLeading
        #endif
    }
    private static var pauseToolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .primaryAction
        #else
        .topBarTrailing
        #endif
    }

    public let leaderboardService: LeaderboardService
    public let ratingService: RatingService
    public let theme: (any GameTheme)?
    public let hapticController: HapticFeedbackController?
    public let fontPreferenceStore: FontPreferenceStore?
    public let highestScoreStore: HighestScoreStore
    public let playLimitService: PlayLimitService?
    public let style: GameViewStyle
    public let inputAdapterFactory: any GameInputAdapterFactory
    private let shouldStartGame: Bool
    private let showMenuButton: Bool
    private let onFinishRequest: (() -> Void)?
    private let onMenuRequest: (() -> Void)?
    private let isMenuOverlayPresented: Binding<Bool>?

    @AppStorage(SoundPreferences.volumeKey) private var sfxVolume: Double = SoundPreferences.defaultVolume
    @State private var model: GameViewModel
    @ScaledMetric(relativeTo: .body) private var directionButtonHeight: CGFloat = 120
    @Environment(\.dismiss) private var dismiss
    @State private var isPaywallPresented = false

    public init(
        leaderboardService: LeaderboardService,
        ratingService: RatingService,
        theme: (any GameTheme)?,
        hapticController: HapticFeedbackController?,
        fontPreferenceStore: FontPreferenceStore?,
        highestScoreStore: HighestScoreStore,
        playLimitService: PlayLimitService?,
        style: GameViewStyle,
        inputAdapterFactory: any GameInputAdapterFactory,
        shouldStartGame: Bool = true,
        showMenuButton: Bool = false,
        onFinishRequest: (() -> Void)? = nil,
        onMenuRequest: (() -> Void)? = nil,
        isMenuOverlayPresented: Binding<Bool>? = nil
    ) {
        self.leaderboardService = leaderboardService
        self.ratingService = ratingService
        self.theme = theme
        self.hapticController = hapticController
        self.fontPreferenceStore = fontPreferenceStore
        self.highestScoreStore = highestScoreStore
        self.playLimitService = playLimitService
        self.style = style
        self.inputAdapterFactory = inputAdapterFactory
        self.shouldStartGame = shouldStartGame
        self.showMenuButton = showMenuButton
        self.onFinishRequest = onFinishRequest
        self.onMenuRequest = onMenuRequest
        self.isMenuOverlayPresented = isMenuOverlayPresented
        AppLog.info(AppLog.game, "GameView init - shouldStartGame: \(shouldStartGame), showMenuButton: \(showMenuButton)")
        _model = State(initialValue: GameViewModel(
            leaderboardService: leaderboardService,
            ratingService: ratingService,
            theme: theme,
            hapticController: hapticController,
            highestScoreStore: highestScoreStore,
            inputAdapterFactory: inputAdapterFactory,
            playLimitService: playLimitService,
            shouldStartGame: shouldStartGame
        ))
    }

    public var body: some View {
        GeometryReader { outer in
            ZStack {
                GameLayoutView(
                    containerSize: outer.size,
                    style: style,
                    score: model.hud.score,
                    lives: model.hud.lives,
                    lifeAssetName: theme?.lifeSprite() ?? "life",
                    bundle: Self.sharedBundle,
                    leftButtonDown: model.controls.leftButtonDown,
                    rightButtonDown: model.controls.rightButtonDown,
                    directionButtonHeight: directionButtonHeight,
                    headerFont: headerFont(size: style.hudFontSize),
                    inputAdapter: model.inputAdapter,
                    onMoveLeft: { model.flashButton(.left) },
                    onMoveRight: { model.flashButton(.right) },
                    onAppearSide: { side in
                        AppLog.info(AppLog.game, "GameLayoutView appeared with side: \(side)")
                        model.setupSceneIfNeeded(side: side, volume: sfxVolume)
                    },
                    onResizeSide: { side in
                        model.updateSceneSizeIfNeeded(side: side)
                    },
                    gameArea: { _ in
                        if let scene = model.scene {
                            SpriteView(scene: scene)
                        } else {
                            Color(red: 202/255, green: 220/255, blue: 159/255)
                        }
                    }
                )
                GameInputOverlay(
                    onLeftTap: handleLeftTap,
                    onRightTap: handleRightTap,
                    onDrag: handleDrag
                )
            }
        }
        #if os(tvOS)
        .focusable()
        .onPlayPauseCommand(perform: model.togglePause)
        .onMoveCommand { direction in
            switch direction {
            case .left:
                handleLeftTap()
            case .right:
                handleRightTap()
            default:
                break
            }
        }
        #endif
        .ignoresSafeArea(edges: .bottom)
        #if os(iOS)
        .persistentSystemOverlays(.hidden)
        .background(InteractivePopGestureDisabler())
        #endif
        .background(gameBackgroundColor)
        .onAppear {
            if let overlayBinding = isMenuOverlayPresented {
                AppLog.info(AppLog.game, "GameView onAppear - overlay presented: \(overlayBinding.wrappedValue)")
                model.setOverlayPause(isPresented: overlayBinding.wrappedValue)
            }
        }
        .toolbar {
            if showMenuButton {
                ToolbarItem(placement: Self.menuToolbarPlacement) {
                    Button {
                        onMenuRequest?()
                    } label: {
                        Label(
                            GameLocalizedStrings.string("menu_button"),
                            systemImage: "arrow.up"
                        )
                        .font(pauseButtonFont)
                    }
                    .accessibilityLabel(GameLocalizedStrings.string("menu_button"))
                }
            }
            ToolbarItem(placement: Self.pauseToolbarPlacement) {
                Button {
                    model.togglePause()
                } label: {
                    Label(
                        GameLocalizedStrings.string(model.pause.isUserPaused ? "resume" : "pause"),
                        systemImage: model.pause.isUserPaused ? "play.fill" : "pause.fill"
                    )
                    .font(pauseButtonFont)
                }
                .accessibilityLabel(GameLocalizedStrings.string(model.pause.isUserPaused ? "resume" : "pause"))
                .disabled(model.pauseButtonDisabled)
                .opacity(model.pauseButtonDisabled ? 0.4 : 1)
            }
        }
        .alert(GameLocalizedStrings.string("gameOver"), isPresented: showGameOverBinding) {
            Button(GameLocalizedStrings.string("restart")) {
                if let playLimitService, playLimitService.canStartNewGame(on: Date()) {
                    model.restartGame()
                } else if playLimitService != nil {
                    isPaywallPresented = true
                } else {
                    model.restartGame()
                }
            }
            Button(GameLocalizedStrings.string("finish")) {
                if let onFinishRequest {
                    onFinishRequest()
                } else {
                    dismiss()
                }
            }
        } message: {
            if model.hud.isNewHighScore {
                Text(GameLocalizedStrings.format("new_high_score_message %lld", model.hud.gameOverScore))
            } else {
                Text(GameLocalizedStrings.format("score %lld", model.hud.gameOverScore))
            }
        }
        .onDisappear {
            model.tearDown()
        }
        .onChange(of: sfxVolume) { _, newValue in
            model.setVolume(newValue)
        }
        .onChange(of: shouldStartGame) { _, newValue in
            AppLog.info(AppLog.game, "GameView shouldStartGame changed from \(model.shouldStartGame) to \(newValue)")
            model.shouldStartGame = newValue
        }
        .onChange(of: isMenuOverlayPresented?.wrappedValue ?? false) { _, isPresented in
            guard isMenuOverlayPresented != nil else { return }
            AppLog.info(AppLog.game, "Menu overlay presented: \(isPresented)")
            model.setOverlayPause(isPresented: isPresented)
        }
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView(playLimitService: playLimitService)
                .fontPreferenceStore(fontPreferenceStore)
        }
        .fontPreferenceStore(fontPreferenceStore)
    }

    /// Background color for the game view. Uses a secondary system background where available
    /// so the gameplay screen is visually distinct from the menu.
    private var gameBackgroundColor: Color {
        #if canImport(UIKit) && !os(watchOS)
        return Color(uiColor: .secondarySystemBackground)
        #else
        return .clear
        #endif
    }

    private var pauseButtonFont: Font {
        fontPreferenceStore?.font(size: style.pauseButtonFontSize)
            ?? .custom("PressStart2P-Regular", size: style.pauseButtonFontSize)
    }

    private func headerFont(size: CGFloat) -> Font {
        fontPreferenceStore?.font(size: size) ?? .custom("PressStart2P-Regular", size: size)
    }

    private var showGameOverBinding: Binding<Bool> {
        Binding(
            get: { model.hud.showGameOver },
            set: { model.hud.showGameOver = $0 }
        )
    }

    private func handleLeftTap() {
        model.flashButton(.left)
        model.inputAdapter?.handleLeft()
    }

    private func handleRightTap() {
        model.flashButton(.right)
        model.inputAdapter?.handleRight()
    }

    private func handleDrag(translation: CGSize) {
        if translation.width < 0 {
            model.flashButton(.left)
        } else {
            model.flashButton(.right)
        }
        model.inputAdapter?.handleDrag(translation: translation)
    }
}
