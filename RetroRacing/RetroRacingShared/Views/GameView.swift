//
//  GameView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI
import SpriteKit
#if canImport(UIKit) && (os(iOS) || os(tvOS))
import UIKit
#endif

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
    public let supportsHapticFeedback: Bool
    public let fontPreferenceStore: FontPreferenceStore?
    public let highestScoreStore: HighestScoreStore
    public let challengeProgressService: ChallengeProgressService
    public let playLimitService: PlayLimitService?
    public let style: GameViewStyle
    public let inputAdapterFactory: any GameInputAdapterFactory
    public let controllerInputSource: any GameControllerInputSource
    public let controlsDescriptionKey: String
    private let shouldStartGame: Bool
    private let showMenuButton: Bool
    private let onFinishRequest: (() -> Void)?
    private let onMenuRequest: (() -> Void)?
    private let onPlayRequest: (() -> Void)?
    private let isMenuOverlayPresented: Binding<Bool>?

    @AppStorage(SoundEffectsVolumeSetting.conditionalDefaultStorageKey)
    private var soundEffectsVolumeData: Data = Data()
    @AppStorage(GameDifficulty.conditionalDefaultStorageKey) private var difficultyStorageData: Data = Data()
    @AppStorage(AudioFeedbackMode.conditionalDefaultStorageKey) private var audioFeedbackModeStorageData: Data = Data()
    @AppStorage(LaneMoveCueStyle.storageKey) private var laneMoveCueStyleRawValue: String = LaneMoveCueStyle.defaultStyle.rawValue
    @AppStorage(BigCarsSetting.conditionalDefaultStorageKey) private var bigCarsData: Data = Data()
    @AppStorage(RoadVisualStyle.storageKey) private var roadVisualStyleRawValue: String = RoadVisualStyle.defaultStyle.rawValue
    @AppStorage(DirectTouchSetting.conditionalDefaultStorageKey) private var directTouchData: Data = Data()
    @AppStorage(SpeedWarningFeedbackMode.conditionalDefaultStorageKey)
    private var speedWarningFeedbackModeData: Data = Data()
    @AppStorage(VoiceOverTutorialPreference.hasSeenInGameVoiceOverTutorialKey)
    private var hasSeenInGameVoiceOverTutorial: Bool = VoiceOverTutorialPreference.defaultHasSeenInGameVoiceOverTutorial
    @AppStorage(DebugGameplayStorageKeys.forcedChallengeIdentifier)
    private var debugForcedChallengeIdentifierRawValue: String = DebugGameplayStorageKeys.noForcedChallengeIdentifier
    @AppStorage(DebugGameplayStorageKeys.showSpriteKitFrameStats)
    private var debugShowSpriteKitFrameStats: Bool = false
    @State private var model: GameViewModel
    @ScaledMetric(relativeTo: .largeTitle) private var directionButtonHeight: CGFloat = 120
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreKitService.self) private var storeKit
    @State private var isPaywallPresented = false
    @State private var pendingFinishRequestAfterGameOverDismiss = false
    @State private var isInGameHelpPresented = false
    @State private var helpPresentationContext: HelpPresentationContext?

    private enum HelpPresentationContext {
        case manual(snapshot: GameViewModel.HelpPauseSnapshot)
        case automatic(shouldResumeOnDismiss: Bool)
    }

    public init(
        leaderboardService: LeaderboardService,
        ratingService: RatingService,
        theme: (any GameTheme)?,
        hapticController: HapticFeedbackController?,
        supportsHapticFeedback: Bool,
        fontPreferenceStore: FontPreferenceStore?,
        highestScoreStore: HighestScoreStore,
        challengeProgressService: ChallengeProgressService,
        playLimitService: PlayLimitService?,
        style: GameViewStyle,
        inputAdapterFactory: any GameInputAdapterFactory,
        controllerInputSource: any GameControllerInputSource,
        controlsDescriptionKey: String,
        shouldStartGame: Bool = true,
        showMenuButton: Bool = false,
        onFinishRequest: (() -> Void)? = nil,
        onMenuRequest: (() -> Void)? = nil,
        onPlayRequest: (() -> Void)? = nil,
        isMenuOverlayPresented: Binding<Bool>? = nil
    ) {
        self.leaderboardService = leaderboardService
        self.ratingService = ratingService
        self.theme = theme
        self.hapticController = hapticController
        self.supportsHapticFeedback = supportsHapticFeedback
        self.fontPreferenceStore = fontPreferenceStore
        self.highestScoreStore = highestScoreStore
        self.challengeProgressService = challengeProgressService
        self.playLimitService = playLimitService
        self.style = style
        self.inputAdapterFactory = inputAdapterFactory
        self.controllerInputSource = controllerInputSource
        self.controlsDescriptionKey = controlsDescriptionKey
        self.shouldStartGame = shouldStartGame
        self.showMenuButton = showMenuButton
        self.onFinishRequest = onFinishRequest
        self.onMenuRequest = onMenuRequest
        self.onPlayRequest = onPlayRequest
        self.isMenuOverlayPresented = isMenuOverlayPresented
        AppLog.info(AppLog.game, "GameView init - shouldStartGame: \(shouldStartGame), showMenuButton: \(showMenuButton)")
        let selectedDifficulty = GameDifficulty.currentSelection(from: InfrastructureDefaults.userDefaults)
        let selectedAudioFeedbackMode = AudioFeedbackMode.currentSelection(from: InfrastructureDefaults.userDefaults)
        let selectedLaneMoveCueStyle = LaneMoveCueStyle.currentSelection(from: InfrastructureDefaults.userDefaults)
        let selectedBigRivalCarsEnabled = BigCarsPreference.currentSelection(from: InfrastructureDefaults.userDefaults)
        let selectedRoadVisualStyle = RoadVisualStyle.currentSelection(from: InfrastructureDefaults.userDefaults)
        _model = State(initialValue: GameViewModel(
            leaderboardService: leaderboardService,
            ratingService: ratingService,
            theme: theme,
            hapticController: hapticController,
            highestScoreStore: highestScoreStore,
            challengeProgressService: challengeProgressService,
            inputAdapterFactory: inputAdapterFactory,
            playLimitService: playLimitService,
            selectedDifficulty: selectedDifficulty,
            selectedAudioFeedbackMode: selectedAudioFeedbackMode,
            selectedLaneMoveCueStyle: selectedLaneMoveCueStyle,
            selectedBigRivalCarsEnabled: selectedBigRivalCarsEnabled,
            selectedRoadVisualStyle: selectedRoadVisualStyle,
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
                    showSpeedAlert: model.hud.speedIncreaseImminent,
                    lifeAssetName: theme?.lifeSprite() ?? "life",
                    bundle: Self.sharedBundle,
                    hideHUDFromAccessibility: false,
                    leftButtonDown: model.controls.leftButtonDown,
                    rightButtonDown: model.controls.rightButtonDown,
                    directionButtonHeight: directionButtonHeight,
                    headerFont: headerFont(textStyle: style.hudTextStyle),
                    inputAdapter: model.inputAdapter,
                    onMoveLeft: { model.flashButton(.left) },
                    onMoveRight: { model.flashButton(.right) },
                    onKeyboardInput: { model.recordControlInput(.keyboard) },
                    onSwipeInput: { model.recordControlInput(.swipe) },
                    onTogglePause: model.togglePause,
                    onAppearSide: { side in
                        AppLog.info(AppLog.game, "GameLayoutView appeared with side: \(side)")
                        model.setupSceneIfNeeded(side: side, volume: selectedSoundEffectsVolume)
                    },
                    onResizeSide: { side in
                        model.updateSceneSizeIfNeeded(side: side)
                    },
                    gameArea: { _ in
                        gameAreaContent
                    }
                )
                GameInputOverlay(
                    onLeftTap: handleLeftTap,
                    onRightTap: handleRightTap,
                    onDrag: handleDrag,
                    isInputEnabled: !isPausedGridExplorationMode,
                    isAccessibilityEnabled: !isPausedGridExplorationMode,
                    isDirectTouchEnabled: selectedDirectTouchEnabled
                )
            }
        }
        #if os(tvOS)
        .focusable()
        .onPlayPauseCommand(perform: model.togglePause)
        .onMoveCommand { direction in
            switch direction {
            case .left:
                handleDirectionalMoveLeft(recordControlInput: nil)
            case .right:
                handleDirectionalMoveRight(recordControlInput: nil)
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
            model.updateDifficulty(selectedDifficulty)
            model.updateAudioFeedbackMode(selectedAudioFeedbackMode)
            model.updateLaneMoveCueStyle(selectedLaneMoveCueStyle)
            model.updateBigRivalCarsEnabled(selectedBigRivalCarsEnabled)
            model.updateRoadVisualStyle(selectedRoadVisualStyle)
            model.setDebugForcedChallengeIdentifier(selectedDebugForcedChallengeIdentifier)
            model.updateDebugSpriteKitFrameStatsVisibility(shouldShowDebugSpriteKitFrameStats)
            model.recordVoiceOverControlIfNeeded()
            if let overlayBinding = isMenuOverlayPresented {
                AppLog.info(AppLog.game, "GameView onAppear - overlay presented: \(overlayBinding.wrappedValue)")
                model.setOverlayPause(isPresented: overlayBinding.wrappedValue)
            }
            attemptAutoPresentVoiceOverHelpIfNeeded()
            startControllerInput()
        }
        #if os(iOS) || os(tvOS) || os(visionOS)
        .accessibilityAction(.magicTap) {
            model.togglePause()
        }
        #endif
        .toolbar {
            if showMenuButton && shouldShowMenuToolbarButton {
                ToolbarItem(placement: Self.menuToolbarPlacement) {
                    Button {
                        model.setOverlayPause(isPresented: true)
                        onMenuRequest?()
                    } label: {
                        Label(
                            GameLocalizedStrings.string("menu_button"),
                            systemImage: "xmark"
                        )
                        .font(pauseButtonFont)
                    }
                    .accessibilityLabel(GameLocalizedStrings.string("menu_button"))
                    .accessibilityHidden(shouldHideGameplayChromeFromAccessibility)
                    .disabled(toolbarControlsDisabled)
                    .opacity(toolbarControlsDisabled ? 0.4 : 1)
                }
            }
            ToolbarItemGroup(placement: Self.pauseToolbarPlacement) {
                Button {
                    presentManualHelp()
                } label: {
                    Label(
                        GameLocalizedStrings.string("tutorial_help_button"),
                        systemImage: "questionmark.circle"
                    )
                    .font(pauseButtonFont)
                }
                .accessibilityLabel(GameLocalizedStrings.string("tutorial_help_button"))
                .accessibilityHidden(shouldHideGameplayChromeFromAccessibility)
                .disabled(toolbarControlsDisabled)
                .opacity(toolbarControlsDisabled ? 0.4 : 1)
                
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
                .accessibilityHidden(shouldHideGameplayChromeFromAccessibility)
                .disabled(model.pauseButtonDisabled || toolbarControlsDisabled)
                .opacity((model.pauseButtonDisabled || toolbarControlsDisabled) ? 0.4 : 1)

                #if os(macOS)
                if shouldShowDisabledSettingsToolbarButton {
                    Button(action: {}) {
                        Label(
                            GameLocalizedStrings.string("settings"),
                            systemImage: "gearshape"
                        )
                        .font(pauseButtonFont)
                    }
                    .accessibilityLabel(GameLocalizedStrings.string("settings"))
                    .disabled(true)
                    .opacity(0.4)
                }
                #endif
            }
        }
        .sheet(isPresented: $isInGameHelpPresented, onDismiss: handleInGameHelpDismissed) {
            makeInGameHelpView()
        }
        .sheet(isPresented: showGameOverBinding, onDismiss: handleGameOverSheetDismissed) {
            GameOverView(
                score: model.hud.gameOverScore,
                bestScore: model.hud.gameOverBestScore,
                difficulty: model.hud.gameOverDifficulty,
                isNewRecord: model.hud.isNewHighScore,
                previousBestScore: model.hud.gameOverPreviousBestScore,
                nextFriendAhead: model.hud.gameOverNextFriendAhead,
                overtakenFriends: model.hud.gameOverOvertakenFriends,
                newlyAchievedChallengeIDs: model.hud.gameOverNewlyAchievedChallengeIDs,
                onRestart: handleRestartFromGameOver,
                onFinish: handleFinishFromGameOver,
                onPresented: model.handleGameOverModalPresentedIfNeeded
            )
            .fontPreferenceStore(fontPreferenceStore)
        }
        .onDisappear {
            controllerInputSource.stop()
            model.tearDown()
        }
        .onChange(of: soundEffectsVolumeData) { _, _ in
            model.setVolume(selectedSoundEffectsVolume)
        }
        .onChange(of: shouldStartGame) { _, newValue in
            AppLog.info(AppLog.game, "GameView shouldStartGame changed from \(model.shouldStartGame) to \(newValue)")
            model.shouldStartGame = newValue
        }
        .onChange(of: difficultyStorageData) { _, _ in
            model.updateDifficulty(selectedDifficulty)
        }
        .onChange(of: audioFeedbackModeStorageData) { _, _ in
            model.updateAudioFeedbackMode(selectedAudioFeedbackMode)
        }
        .onChange(of: laneMoveCueStyleRawValue) { _, _ in
            model.updateLaneMoveCueStyle(selectedLaneMoveCueStyle)
        }
        .onChange(of: bigCarsData) { _, _ in
            model.updateBigRivalCarsEnabled(selectedBigRivalCarsEnabled)
        }
        .onChange(of: roadVisualStyleRawValue) { _, _ in
            model.updateRoadVisualStyle(selectedRoadVisualStyle)
        }
        .onChange(of: speedWarningFeedbackModeData) { _, _ in
            if model.hud.speedIncreaseImminent {
                announceSpeedIncreaseIfNeeded(oldValue: false, newValue: true)
            }
        }
        .onChange(of: debugForcedChallengeIdentifierRawValue) { _, _ in
            model.setDebugForcedChallengeIdentifier(selectedDebugForcedChallengeIdentifier)
        }
        .onChange(of: debugShowSpriteKitFrameStats) { _, _ in
            model.updateDebugSpriteKitFrameStatsVisibility(shouldShowDebugSpriteKitFrameStats)
        }
        .onChange(of: model.pause.scenePaused) { _, _ in
            attemptAutoPresentVoiceOverHelpIfNeeded()
        }
        .onChange(of: model.hud.speedIncreaseImminent) { oldValue, newValue in
            announceSpeedIncreaseIfNeeded(oldValue: oldValue, newValue: newValue)
        }
        .onChange(of: isMenuOverlayPresented?.wrappedValue ?? false) { _, isPresented in
            guard isMenuOverlayPresented != nil else { return }
            AppLog.info(AppLog.game, "Menu overlay presented: \(isPresented)")
            model.setOverlayPause(isPresented: isPresented)
        }
        .sheet(isPresented: $isPaywallPresented) {
            PaywallView(playLimitService: playLimitService, isLimitReached: true)
                .fontPreferenceStore(fontPreferenceStore)
        }
        .fontPreferenceStore(fontPreferenceStore)
    }

    /// Background color for the game view. Uses a secondary system background where available
    /// so the gameplay screen is visually distinct from the menu.
    private var gameBackgroundColor: Color {
        #if canImport(UIKit) && !os(watchOS) && !os(tvOS)
        return Color(uiColor: .secondarySystemBackground)
        #else
        return .clear
        #endif
    }

    private var pauseButtonFont: Font {
        fontPreferenceStore?.font(fixedSize: style.pauseButtonFontSize)
            ?? .custom("PressStart2P-Regular", size: style.pauseButtonFontSize)
    }

    private func headerFont(textStyle: Font.TextStyle) -> Font {
        fontPreferenceStore?.font(textStyle: textStyle) ?? .system(textStyle, design: .default)
    }

    private var showGameOverBinding: Binding<Bool> {
        Binding(
            get: { model.hud.showGameOver },
            set: { model.hud.showGameOver = $0 }
        )
    }

    @ViewBuilder
    private var gameAreaContent: some View {
        if let scene = model.scene {
            ZStack {
                spriteSceneView(for: scene)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .accessibilityRespondsToUserInteraction(false)
                if isPausedGridExplorationMode {
                    PausedGridAccessibilityOverlay(gridState: scene.gridState)
                }
            }
        } else {
            Color(red: 202/255, green: 220/255, blue: 159/255)
        }
    }

    @ViewBuilder
    private func spriteSceneView(for scene: GameScene) -> some View {
        SpriteView(scene: scene)
    }

    private var selectedDifficulty: GameDifficulty {
        GameDifficulty.currentSelection(from: InfrastructureDefaults.userDefaults)
    }

    private var selectedAudioFeedbackMode: AudioFeedbackMode {
        AudioFeedbackMode.currentSelection(from: InfrastructureDefaults.userDefaults)
    }

    private var selectedLaneMoveCueStyle: LaneMoveCueStyle {
        _ = laneMoveCueStyleRawValue
        return LaneMoveCueStyle.currentSelection(from: InfrastructureDefaults.userDefaults)
    }

    private var selectedBigRivalCarsEnabled: Bool {
        BigCarsPreference.currentSelection(from: InfrastructureDefaults.userDefaults)
    }

    private var selectedRoadVisualStyle: RoadVisualStyle {
        _ = roadVisualStyleRawValue
        return RoadVisualStyle.currentSelection(from: InfrastructureDefaults.userDefaults)
    }

    private var selectedDirectTouchEnabled: Bool {
        _ = directTouchData
        return DirectTouchPreference.currentSelection(from: InfrastructureDefaults.userDefaults)
    }

    private var selectedDebugForcedChallengeIdentifier: ChallengeIdentifier? {
        guard BuildConfiguration.shouldShowDebugFeatures else { return nil }
        return ChallengeIdentifier.resolvedFromStoredRawValue(debugForcedChallengeIdentifierRawValue)
    }

    private var shouldShowDebugSpriteKitFrameStats: Bool {
        BuildConfiguration.shouldShowDebugFeatures && debugShowSpriteKitFrameStats
    }

    private var hasScene: Bool {
        model.scene != nil
    }

    private var isVoiceOverRunning: Bool {
        VoiceOverStatus.isVoiceOverRunning
    }

    private var shouldHideGameplayChromeFromAccessibility: Bool {
        isVoiceOverRunning
    }

    private var isPausedGridExplorationMode: Bool {
        isVoiceOverRunning && model.pause.isExplicitUserPauseActive
    }

    private var toolbarControlsDisabled: Bool {
        let overlayPresented = isMenuOverlayPresented?.wrappedValue ?? false
        return shouldStartGame == false || overlayPresented
    }

    private var shouldShowMenuToolbarButton: Bool {
        let overlayPresented = isMenuOverlayPresented?.wrappedValue ?? false
        return overlayPresented == false
    }

    #if os(macOS)
    private var shouldShowDisabledSettingsToolbarButton: Bool {
        let overlayPresented = isMenuOverlayPresented?.wrappedValue ?? false
        return showMenuButton && overlayPresented == false
    }
    #endif

    private func startControllerInput() {
        let capturedModel = model
        let menuOverlayBinding = isMenuOverlayPresented
        let playRequest = onPlayRequest
        let isHelpPresentedProvider = { isInGameHelpPresented }
        AppLog.info(AppLog.game, "Starting controller input in GameView")
        controllerInputSource.start { @MainActor action in
            let isOverlayVisible = (menuOverlayBinding?.wrappedValue ?? false) || isHelpPresentedProvider()
            let route = GameControllerActionRouter.route(
                action: action,
                isMenuOverlayVisible: isOverlayVisible
            )
            AppLog.info(
                AppLog.game,
                "Controller action routed: action=\(action), route=\(route), overlayVisible=\(isOverlayVisible), hasScene=\(capturedModel.scene != nil), hasInputAdapter=\(capturedModel.inputAdapter != nil)"
            )
            switch route {
            case .ignored:
                return
            case .moveLeft:
                capturedModel.recordControlInput(.gameController)
                capturedModel.flashButton(.left)
                guard let inputAdapter = capturedModel.inputAdapter else {
                    AppLog.error(AppLog.game, "Controller moveLeft ignored because inputAdapter is nil")
                    return
                }
                inputAdapter.handleLeft()
            case .moveRight:
                capturedModel.recordControlInput(.gameController)
                capturedModel.flashButton(.right)
                guard let inputAdapter = capturedModel.inputAdapter else {
                    AppLog.error(AppLog.game, "Controller moveRight ignored because inputAdapter is nil")
                    return
                }
                inputAdapter.handleRight()
            case .togglePause:
                capturedModel.recordControlInput(.gameController)
                capturedModel.togglePause()
            case .requestPlay:
                capturedModel.recordControlInput(.gameController)
                playRequest?()
            }
        }
    }

    private func handleLeftTap() {
        handleDirectionalMoveLeft(recordControlInput: .tap)
    }

    private func handleRightTap() {
        handleDirectionalMoveRight(recordControlInput: .tap)
    }

    private func handleDrag(translation: CGSize) {
        model.recordControlInput(.swipe)
        if translation.width < 0 {
            model.flashButton(.left)
        } else {
            model.flashButton(.right)
        }
        model.inputAdapter?.handleDrag(translation: translation)
    }

    private func handleDirectionalMoveLeft(recordControlInput: ChallengeControlInput?) {
        if let recordControlInput {
            model.recordControlInput(recordControlInput)
        }
        model.flashButton(.left)
        model.inputAdapter?.handleLeft()
    }

    private func handleDirectionalMoveRight(recordControlInput: ChallengeControlInput?) {
        if let recordControlInput {
            model.recordControlInput(recordControlInput)
        }
        model.flashButton(.right)
        model.inputAdapter?.handleRight()
    }

    private func handleRestartFromGameOver() {
        // Premium users always have unlimited plays.
        if storeKit.hasPremiumAccess {
            model.restartGame()
        } else if let playLimitService, playLimitService.canStartNewGame(on: Date()) {
            model.restartGame()
        } else if playLimitService != nil {
            model.dismissGameOverModal()
            isPaywallPresented = true
        } else {
            model.restartGame()
        }
    }

    private func handleFinishFromGameOver() {
        pendingFinishRequestAfterGameOverDismiss = true
        model.dismissGameOverModal()
    }

    private func handleGameOverSheetDismissed() {
        guard pendingFinishRequestAfterGameOverDismiss else { return }
        pendingFinishRequestAfterGameOverDismiss = false
        if let onFinishRequest {
            onFinishRequest()
        } else {
            dismiss()
        }
    }

    private func announceSpeedIncreaseIfNeeded(oldValue: Bool, newValue: Bool) {
        guard oldValue == false, newValue else { return }
        let selectedMode = SpeedWarningFeedbackPreference.currentSelection(
            from: InfrastructureDefaults.userDefaults,
            supportsHaptics: supportsHapticFeedback,
            isVoiceOverRunning: VoiceOverStatus.isVoiceOverRunning
        )
        makeSpeedWarningFeedbackPlayer {
            model.scene?.playSpeedIncreaseWarningSound()
        }
        .play(mode: selectedMode)
    }

    private func attemptAutoPresentVoiceOverHelpIfNeeded() {
        guard InGameHelpPresentationPolicy.shouldAutoPresent(
            voiceOverRunning: VoiceOverStatus.isVoiceOverRunning,
            hasSeenTutorial: hasSeenInGameVoiceOverTutorial,
            shouldStartGame: shouldStartGame,
            hasScene: hasScene,
            isScenePaused: model.pause.scenePaused
        ) else { return }
        presentAutomaticHelp()
    }

    private func presentManualHelp() {
        let snapshot = model.beginManualHelpPresentation()
        helpPresentationContext = .manual(snapshot: snapshot)
        if VoiceOverStatus.isVoiceOverRunning {
            hasSeenInGameVoiceOverTutorial = true
        }
        isInGameHelpPresented = true
    }

    private func presentAutomaticHelp() {
        let shouldResumeOnDismiss = model.beginAutomaticHelpPresentation()
        helpPresentationContext = .automatic(shouldResumeOnDismiss: shouldResumeOnDismiss)
        hasSeenInGameVoiceOverTutorial = true
        isInGameHelpPresented = true
    }

    private func handleInGameHelpDismissed() {
        guard let helpPresentationContext else { return }
        switch helpPresentationContext {
        case .manual(let snapshot):
            model.endManualHelpPresentation(using: snapshot)
        case .automatic(let shouldResumeOnDismiss):
            model.endAutomaticHelpPresentation(shouldResumeOnDismiss: shouldResumeOnDismiss)
        }
        self.helpPresentationContext = nil
    }

    private var selectedSoundEffectsVolume: Double {
        SoundEffectsVolumePreference.currentSelection(from: InfrastructureDefaults.userDefaults)
    }

    @ViewBuilder
    private func makeInGameHelpView() -> some View {
        let previewDependencies = settingsPreviewDependencyFactory.make(
            hapticController: hapticController
        )
        InGameHelpView(
            controlsDescriptionKey: controlsDescriptionKey,
            supportsHapticFeedback: supportsHapticFeedback,
            hapticController: hapticController,
            audioCueTutorialPreviewPlayer: previewDependencies.audioCueTutorialPreviewPlayer,
            speedWarningFeedbackPreviewPlayer: previewDependencies.speedWarningFeedbackPreviewPlayer
        )
        .fontPreferenceStore(fontPreferenceStore)
    }

    private var settingsPreviewDependencyFactory: SettingsPreviewDependencyFactory {
        SettingsPreviewDependencyFactory(
            laneCuePlayerFactory: { PlatformFactories.makeLaneCuePlayer() },
            announcementPoster: AccessibilityAnnouncementPoster(),
            announcementTextProvider: {
                GameLocalizedStrings.string("speed_increase_announcement")
            },
            volumeProvider: {
                selectedSoundEffectsVolume
            }
        )
    }

    private func makeSpeedWarningFeedbackPlayer(
        playWarningSound: @escaping @MainActor @Sendable () -> Void
    ) -> SpeedIncreaseWarningFeedbackPlayer {
        SpeedIncreaseWarningFeedbackPlayer(
            announcementPoster: AccessibilityAnnouncementPoster(),
            hapticController: hapticController,
            playWarningSound: playWarningSound,
            announcementTextProvider: {
                GameLocalizedStrings.string("speed_increase_announcement")
            }
        )
    }
}
