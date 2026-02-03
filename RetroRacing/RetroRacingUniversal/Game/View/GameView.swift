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

/// Bundles HUD-related state for clarity and predictable updates.
struct HUDState {
    var score: Int = 0
    var lives: Int = 3
    var showGameOver: Bool = false
    var gameOverScore: Int = 0
}

/// Tracks pause states separately from HUD to avoid unrelated view updates.
struct PauseState {
    var scenePaused: Bool = false     // reflects scene state (crash/start pauses)
    var isUserPaused: Bool = false    // user-requested pause state

    var pauseButtonDisabled: Bool {
        scenePaused && isUserPaused == false
    }
}

/// Handles transient control visuals and their timers.
struct ControlState {
    var leftButtonDown: Bool = false
    var rightButtonDown: Bool = false
    var leftFlashTask: Task<Void, Never>?
    var rightFlashTask: Task<Void, Never>?

    mutating func cancelFlashTasks() {
        leftFlashTask?.cancel()
        rightFlashTask?.cancel()
        leftFlashTask = nil
        rightFlashTask = nil
    }
}

/// Collects scene-scoped references to keep lifecycle wiring together.
struct SceneContext {
    var sceneBox = GameSceneBox()
    var delegate: GameSceneDelegateImpl?
    var inputAdapter: GameInputAdapter?
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
    @State var sceneContext = SceneContext()
    @State var hud = HUDState()
    @State var pause = PauseState()
    @State var controls = ControlState()
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

    private var pauseButtonDisabled: Bool {
        pause.pauseButtonDisabled
    }

    private func binding<Value>(_ keyPath: WritableKeyPath<HUDState, Value>) -> Binding<Value> {
        Binding(
            get: { hud[keyPath: keyPath] },
            set: { hud[keyPath: keyPath] = $0 }
        )
    }

    @ViewBuilder
    func gameAreaWithFullScreenTouch() -> some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            gameAreaContent(side: side)
                .frame(width: side, height: side)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .modifier(GameAreaKeyboardModifier(
                    inputAdapter: sceneContext.inputAdapter,
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
                            sceneContext.inputAdapter?.handleLeft()
                        }
                        .accessibilityLabel(GameLocalizedStrings.string("move_left"))
                        .accessibilityHint(GameLocalizedStrings.string("move_left_hint"))
                        .accessibilityAddTraits(.isButton)
                    Color.clear
                        .contentShape(Rectangle())
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .onTapGesture {
                            flashButton(.right)
                            sceneContext.inputAdapter?.handleRight()
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
                            sceneContext.inputAdapter?.handleDrag(translation: value.translation)
                        }
                )
            }
        }
        #if os(macOS) || os(iOS)
        .focusable()
        .focused($isGameAreaFocused)
        .onKeyPress(.leftArrow) {
            guard let scene = sceneContext.sceneBox.scene else { return .ignored }
            flashButton(.left)
            scene.moveLeft()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            guard let scene = sceneContext.sceneBox.scene else { return .ignored }
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
                        GameLocalizedStrings.string(pause.isUserPaused ? "resume" : "pause"),
                        systemImage: pause.isUserPaused ? "play.fill" : "pause.fill"
                    )
                }
                .accessibilityLabel(GameLocalizedStrings.string(pause.isUserPaused ? "resume" : "pause"))
                .disabled(pauseButtonDisabled)
                .opacity(pauseButtonDisabled ? 0.4 : 1)
            }
        }
        .alert(GameLocalizedStrings.string("gameOver"), isPresented: binding(\.showGameOver)) {
            Button(GameLocalizedStrings.string("restart")) {
                sceneContext.sceneBox.scene?.start()
                if let scene = sceneContext.sceneBox.scene {
                    let (currentScore, currentLives) = Self.scoreAndLives(from: scene)
                    hud.score = currentScore
                    hud.lives = currentLives
                }
                hud.showGameOver = false
            }
            Button(GameLocalizedStrings.string("finish")) {
                dismiss()
            }
        } message: {
            Text(GameLocalizedStrings.format("score %lld", hud.gameOverScore))
        }
        .onDisappear {
            // Tear down so re-entering from the menu always creates a fresh scene/run.
            controls.cancelFlashTasks()
            sceneContext.sceneBox.scene?.stopAllSounds()
            sceneContext.sceneBox.scene = nil
            sceneContext.delegate = nil
            sceneContext.inputAdapter = nil
        }
        .onChange(of: sfxVolume) { _, newValue in
            sceneContext.sceneBox.scene?.setSoundVolume(newValue)
        }
    }

    private enum ButtonSide { case left, right }

    private func togglePause() {
        guard let scene = sceneContext.sceneBox.scene, pauseButtonDisabled == false else { return }
        if pause.isUserPaused {
            scene.unpauseGameplay()
            pause.isUserPaused = false
        } else {
            scene.pauseGameplay()
            pause.isUserPaused = true
        }
    }

    private func flashButton(_ side: ButtonSide) {
        switch side {
        case .left: controls.leftFlashTask?.cancel()
        case .right: controls.rightFlashTask?.cancel()
        }

        withAnimation(.easeOut(duration: 0.05)) {
            switch side {
            case .left: controls.leftButtonDown = true
            case .right: controls.rightButtonDown = true
            }
        }

        let task = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(150))
            withAnimation(.easeOut(duration: 0.05)) {
                switch side {
                case .left: controls.leftButtonDown = false
                case .right: controls.rightButtonDown = false
                }
            }
        }

        switch side {
        case .left: controls.leftFlashTask = task
        case .right: controls.rightFlashTask = task
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
