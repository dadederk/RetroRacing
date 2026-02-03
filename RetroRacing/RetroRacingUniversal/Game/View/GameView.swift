//
//  GameView.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI
import SpriteKit
import RetroRacingShared
import Observation

/// Holder to keep a single SKScene instance alive across SwiftUI view reloads (e.g. rotation).
@Observable
final class GameSceneBox {
    var scene: GameScene?
}

/// SwiftUI game screen that hosts the shared SpriteKit scene and routes platform input.
struct GameView: View {
    static let sharedBundle = Bundle(for: GameScene.self)
    private static var pauseToolbarPlacement: ToolbarItemPlacement {
        #if os(macOS)
        .primaryAction
        #else
        .topBarTrailing
        #endif
    }

    let leaderboardService: LeaderboardService
    let ratingService: RatingService
    let theme: (any GameTheme)?
    let hapticController: HapticFeedbackController?
    let fontPreferenceStore: FontPreferenceStore?

    @AppStorage(SoundPreferences.volumeKey) var sfxVolume: Double = SoundPreferences.defaultVolume
    @State var sceneBox = GameSceneBox()
    @State var score: Int = 0
    @State var lives: Int = 3
    @State var scenePaused: Bool = false          // reflects scene state (crash/start pauses)
    @State var isUserPaused: Bool = false         // user-requested pause state
    @State var showGameOver = false
    @State var gameOverScore: Int = 0
    @State var delegate: GameSceneDelegateImpl?
    @State var leftButtonDown = false
    @State var rightButtonDown = false
    @State var inputAdapter: GameInputAdapter?
    @ScaledMetric(relativeTo: .body) var directionButtonHeight: CGFloat = 120
    @Environment(\.dismiss) var dismiss
    #if os(macOS) || os(iOS)
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @Environment(\.verticalSizeClass) var verticalSizeClass
    @FocusState var isGameAreaFocused: Bool
    #endif

    private var pauseButtonDisabled: Bool {
        scenePaused && isUserPaused == false
    }

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
                .modifier(GameAreaKeyboardModifier(
                    inputAdapter: inputAdapter,
                    onMoveLeft: { flashButton(.left) },
                    onMoveRight: { flashButton(.right) }
                ))
                .onAppear {
                    setFocusForGameArea()
                    setupSceneAndDelegateIfNeeded(side: side)
                }
                .onChange(of: geo.size) { _, newSize in
                    updateSceneSizeIfNeeded(side: min(newSize.width, newSize.height))
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
                            flashButton(.left)
                            inputAdapter?.handleLeft()
                        }
                        .accessibilityLabel(GameLocalizedStrings.string("move_left"))
                        .accessibilityHint(GameLocalizedStrings.string("move_left_hint"))
                        .accessibilityAddTraits(.isButton)
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            flashButton(.right)
                            inputAdapter?.handleRight()
                        }
                        .accessibilityLabel(GameLocalizedStrings.string("move_right"))
                        .accessibilityHint(GameLocalizedStrings.string("move_right_hint"))
                        .accessibilityAddTraits(.isButton)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            guard value.translation.width != 0 else { return }
                            if value.translation.width < 0 { flashButton(.left) } else { flashButton(.right) }
                            inputAdapter?.handleDrag(translation: value.translation)
                        }
                )
            }
        }
        #if os(macOS) || os(iOS)
        .focusable()
        .focused($isGameAreaFocused)
        .onKeyPress(.leftArrow) {
            guard let scene = sceneBox.scene else { return .ignored }
            flashButton(.left)
            scene.moveLeft()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            guard let scene = sceneBox.scene else { return .ignored }
            flashButton(.right)
            scene.moveRight()
            return .handled
        }
        #endif
        .ignoresSafeArea(edges: .bottom)
        #if os(iOS)
        .persistentSystemOverlays(.hidden)
        .background(InteractivePopGestureDisabler())
        #endif
        .toolbar {
            ToolbarItem(placement: Self.pauseToolbarPlacement) {
                Button {
                    togglePause()
                } label: {
                    Label(
                        GameLocalizedStrings.string(isUserPaused ? "resume" : "pause"),
                        systemImage: isUserPaused ? "play.fill" : "pause.fill"
                    )
                }
                .accessibilityLabel(GameLocalizedStrings.string(isUserPaused ? "resume" : "pause"))
                .disabled(pauseButtonDisabled)
                .opacity(pauseButtonDisabled ? 0.4 : 1)
            }
        }
        .alert(GameLocalizedStrings.string("gameOver"), isPresented: $showGameOver) {
            Button(GameLocalizedStrings.string("restart")) {
                sceneBox.scene?.start()
                if let scene = sceneBox.scene {
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
        .onDisappear {
            // Tear down so re-entering from the menu always creates a fresh scene/run.
            sceneBox.scene?.stopAllSounds()
            sceneBox.scene = nil
            delegate = nil
            inputAdapter = nil
        }
        .onChange(of: sfxVolume) { _, newValue in
            sceneBox.scene?.setSoundVolume(newValue)
        }
    }

    private enum ButtonSide { case left, right }

    private func togglePause() {
        guard let scene = sceneBox.scene, pauseButtonDisabled == false else { return }
        if isUserPaused {
            scene.unpauseGameplay()
            isUserPaused = false
        } else {
            scene.pauseGameplay()
            isUserPaused = true
        }
    }

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

#if os(iOS)
/// Disables the iOS interactive pop (swipe-back) gesture while the game view is visible so drag controls
/// are not intercepted by the navigation controller. Restores the previous state on exit.
private struct InteractivePopGestureDisabler: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> Controller {
        Controller()
    }

    func updateUIViewController(_ uiViewController: Controller, context: Context) {}

    final class Controller: UIViewController {
        private var previousEnabled: Bool?

        override func viewWillAppear(_ animated: Bool) {
            super.viewWillAppear(animated)
            guard let gesture = navigationController?.interactivePopGestureRecognizer else { return }
            previousEnabled = gesture.isEnabled
            gesture.isEnabled = false
        }

        override func viewWillDisappear(_ animated: Bool) {
            super.viewWillDisappear(animated)
            restoreGestureState()
        }

        deinit {
            restoreGestureState()
        }

        private func restoreGestureState() {
            guard let gesture = navigationController?.interactivePopGestureRecognizer else { return }
            // Default back to enabled if we never captured a prior state.
            gesture.isEnabled = previousEnabled ?? true
        }
    }
}
#endif
