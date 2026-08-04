//
//  ScreenshotCaptureRootView.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 23/07/2026.
//

import SwiftUI
import RetroRacingShared

struct ScreenshotCaptureDependencies {
    let leaderboardService: LeaderboardService
    let gameCenterService: GameCenterService
    let leaderboardConfiguration: LeaderboardConfiguration
    let authenticationPresenter: AuthenticationPresenter
    let ratingService: RatingService
    let themeManager: ThemeManager
    let fontPreferenceStore: FontPreferenceStore
    let screenshotFontPreferenceStore: FontPreferenceStore
    let hapticController: HapticFeedbackController
    let supportsHapticFeedback: Bool
    let highestScoreStore: HighestScoreStore
    let achievementProgressService: AchievementProgressService
    let playLimitService: PlayLimitService
    let specialEventService: SpecialEventService
    let sharePlayMatchService: any SharePlayMatchService
    let controllerInputSource: any GameControllerInputSource
    let controlsDescriptionKey: String
    let settingsPreviewDependencies: SettingsPreviewDependencies
}

struct ScreenshotCaptureRootView: View {
    let configuration: ScreenshotCaptureConfiguration
    let dependencies: ScreenshotCaptureDependencies

    @Environment(StoreKitService.self) private var storeKit
    @State private var isLayoutReady = false
    @State private var isGameplayReady = false
    @State private var isSheetReady = false
    @State private var isSettingsSheetPresented = false
    @State private var isGameOverSheetPresented = false
    @State private var isAchievementSheetPresented = false
    @State private var isMenuReady = false
    @State private var isGameplayOverlayPaused = false

    var body: some View {
        layoutReadyContent
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .fontPreferenceStore(dependencies.screenshotFontPreferenceStore)
            .screenshotCaptureLocaleEnvironment()
            .screenshotCaptureColorScheme()
            .transaction { transaction in
                transaction.disablesAnimations = true
            }
            .onAppear {
                ScreenshotCaptureReadinessSignal.captureRootAppeared(
                    stagingDirectory: configuration.stagingDirectory,
                    slideIndex: configuration.slideIndex
                )
                #if os(macOS)
                ScreenshotCaptureMacWindowLayout.applyLandscapeCaptureSize()
                ScreenshotCaptureLaunchDiagnostics.writeCaptureModeSnapshot(
                    to: configuration.stagingDirectory,
                    slideIndex: configuration.slideIndex
                )
                #endif
                if configuration.fixture.presentsGameOverSheet {
                    isGameplayOverlayPaused = true
                }
                if configuration.fixture.presentsSettingsSheet {
                    storeKit.debugPremiumSimulationMode = .unlimitedPlays
                    #if os(macOS)
                    isGameplayOverlayPaused = true
                    #endif
                }
                if configuration.fixture.presentsMenu {
                    storeKit.debugPremiumSimulationMode = .freemium
                }
            }
            .onChange(of: isLayoutReady) { _, isReady in
                guard isReady else { return }
                ScreenshotCaptureReadinessSignal.markReady(
                    stagingDirectory: configuration.stagingDirectory,
                    slideIndex: configuration.slideIndex
                )
            }
            .overlay(alignment: .topLeading) {
                if isLayoutReady {
                    ScreenshotCaptureReadinessMarker(identifier: configuration.readinessIdentifier)
                }
            }
            #if os(macOS)
            .frame(
                minWidth: ScreenshotCaptureWindowConfiguration.macLandscapeContentSize.width,
                minHeight: ScreenshotCaptureWindowConfiguration.macLandscapeContentSize.height
            )
            #endif
            .sheet(isPresented: $isSettingsSheetPresented) {
                if let focus = settingsFocus {
                    settingsView(focus: focus)
                        #if os(iOS)
                        .presentationBackground(Color(uiColor: .systemGroupedBackground))
                        #endif
                }
            }
            .sheet(isPresented: $isGameOverSheetPresented) {
                gameOverView
            }
            .sheet(isPresented: $isAchievementSheetPresented) {
                AchievementUnlockView(
                    achievementID: .controlVoiceOver,
                    onDone: {}
                )
                .fontPreferenceStore(dependencies.screenshotFontPreferenceStore)
            }
    }

    @ViewBuilder
    private var layoutReadyContent: some View {
        if isLayoutReady {
            captureContent
                .accessibilityElement(children: .contain)
                .accessibilityIdentifier(configuration.readinessIdentifier)
        } else {
            captureContent
        }
    }

    @ViewBuilder
    private var captureContent: some View {
        if configuration.fixture.presentsMenu {
            freeUserMenuCaptureView
        } else if configuration.fixture.presentsSettingsSheet {
            settingsSlideCaptureContent
        } else {
            gameplayCaptureView
        }
    }

    @ViewBuilder
    private var settingsSlideCaptureContent: some View {
        #if os(macOS)
        ZStack {
            menuBackgroundGameplayCaptureView
            menuOverlayCaptureView
        }
        #else
        menuCaptureView(presentsSettingsOnAppear: true)
        #endif
    }

    #if os(macOS)
    private var menuOverlayCaptureView: some View {
        ZStack {
            Color.clear
                .background(.regularMaterial)
                .ignoresSafeArea()
            menuCaptureView(presentsSettingsOnAppear: false)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var menuBackgroundGameplayCaptureView: some View {
        gameplayCaptureView(
            layout: configuration.fixture.gameplayBackgroundLayout,
            readinessIdentifier: nil,
            onLayoutReady: handleMenuBackgroundGameplayReady
        )
    }
    #endif

    private func menuCaptureView(presentsSettingsOnAppear: Bool) -> some View {
        MenuView(
            leaderboardService: dependencies.leaderboardService,
            gameCenterService: dependencies.gameCenterService,
            ratingService: dependencies.ratingService,
            leaderboardConfiguration: dependencies.leaderboardConfiguration,
            authenticationPresenter: dependencies.authenticationPresenter,
            themeManager: dependencies.themeManager,
            fontPreferenceStore: dependencies.screenshotFontPreferenceStore,
            hapticController: dependencies.hapticController,
            supportsHapticFeedback: dependencies.supportsHapticFeedback,
            highestScoreStore: dependencies.highestScoreStore,
            achievementProgressService: dependencies.achievementProgressService,
            playLimitService: dependencies.playLimitService,
            specialEventService: dependencies.specialEventService,
            style: .universal,
            settingsStyle: .universal,
            gameViewStyle: .universal,
            controlsDescriptionKey: dependencies.controlsDescriptionKey,
            showRateButton: true,
            inputAdapterFactory: TouchInputAdapterFactory(),
            onSettingsRequest: presentSettingsSheetFromMenu,
            onPlayWithFriendsRequest: showsPlayWithFriendsOnMenu ? {} : nil
        )
        .fontPreferenceStore(dependencies.screenshotFontPreferenceStore)
        .onAppear {
            #if !os(macOS)
            if presentsSettingsOnAppear {
                presentSettingsSheetFromMenu()
            }
            #endif
        }
    }

    private var freeUserMenuCaptureView: some View {
        menuCaptureView(presentsSettingsOnAppear: false)
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    handleMenuScreenshotReady()
                }
            }
    }

    private var gameplayCaptureView: some View {
        gameplayCaptureView(
            layout: activeScreenshotLayout,
            readinessIdentifier: configuration.readinessIdentifier,
            onLayoutReady: handleGameplayLayoutReady
        )
    }

    private func gameplayCaptureView(
        layout: GameScreenshotLayout,
        readinessIdentifier: String?,
        onLayoutReady: @escaping () -> Void
    ) -> some View {
        GameView(
            leaderboardService: dependencies.leaderboardService,
            ratingService: dependencies.ratingService,
            theme: gameplayTheme,
            hapticController: dependencies.hapticController,
            supportsHapticFeedback: dependencies.supportsHapticFeedback,
            fontPreferenceStore: dependencies.screenshotFontPreferenceStore,
            highestScoreStore: dependencies.highestScoreStore,
            achievementProgressService: dependencies.achievementProgressService,
            playLimitService: dependencies.playLimitService,
            specialEventService: dependencies.specialEventService,
            sharePlayMatchService: dependencies.sharePlayMatchService,
            sharePlayUIState: sharePlayUIState,
            style: .universal,
            inputAdapterFactory: TouchInputAdapterFactory(),
            controllerInputSource: dependencies.controllerInputSource,
            controlsDescriptionKey: dependencies.controlsDescriptionKey,
            shouldStartGame: true,
            showMenuButton: false,
            screenshotLayout: layout,
            screenshotReadinessIdentifier: readinessIdentifier,
            onScreenshotLayoutReady: onLayoutReady,
            isMenuOverlayPresented: $isGameplayOverlayPaused
        )
        .navigationTitle("")
    }

    private func settingsView(focus: ScreenshotSettingsFocus) -> some View {
        SettingsView(
            themeManager: dependencies.themeManager,
            fontPreferenceStore: dependencies.screenshotFontPreferenceStore,
            supportsHapticFeedback: dependencies.supportsHapticFeedback,
            hapticController: dependencies.hapticController,
            audioCueTutorialPreviewPlayer: dependencies.settingsPreviewDependencies.audioCueTutorialPreviewPlayer,
            speedWarningFeedbackPreviewPlayer: dependencies.settingsPreviewDependencies.speedWarningFeedbackPreviewPlayer,
            controlsDescriptionKey: dependencies.controlsDescriptionKey,
            style: .universal,
            achievementProgressService: dependencies.achievementProgressService,
            playLimitService: dependencies.playLimitService,
            specialEventService: dependencies.specialEventService,
            screenshotFocus: focus,
            screenshotFriendOvertakeAnnouncementsEnabled: focus == .accessibility ? false : nil,
            screenshotPresentedInSheet: true,
            onScreenshotLayoutReady: handleSheetLayoutReady
        )
        .fontPreferenceStore(dependencies.screenshotFontPreferenceStore)
        .settingsSheetStyle()
    }

    private var gameOverView: some View {
        GameOverView(
            score: ScreenshotFixtureCatalog.gameOverRunScore,
            bestScore: ScreenshotFixtureCatalog.gameOverBestScore,
            difficulty: .fast,
            isNewRecord: true,
            previousBestScore: ScreenshotFixtureCatalog.gameOverPreviousBestScore,
            nextFriendAhead: ScreenshotFixtureCatalog.rivalFriendAheadSummary,
            overtakenFriends: [],
            onRestart: {},
            onFinish: {},
            onPresented: {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                    handleSheetLayoutReady()
                }
            }
        )
        .fontPreferenceStore(dependencies.screenshotFontPreferenceStore)
    }

    private var activeScreenshotLayout: GameScreenshotLayout {
        configuration.fixture.layout ?? configuration.fixture.gameplayBackgroundLayout
    }

    private var settingsFocus: ScreenshotSettingsFocus? {
        if case .settings(let focus) = configuration.fixture.route {
            return focus
        }
        return nil
    }

    private var gameplayTheme: any GameTheme {
        let platformConfig = ThemePlatformConfig.screenshotCapture(
            platform: ScreenshotCaptureConfiguration.capturePlatform
        )
        let themeID = configuration.fixture.themeID(
            for: ScreenshotCaptureConfiguration.capturePlatform
        )
        return platformConfig.availableThemes.first {
            $0.id == themeID
        } ?? platformConfig.defaultTheme
    }

    private var sharePlayUIState: SharePlayUIState {
        guard configuration.fixture.usesSharePlayWaitingOverlay else { return .idle }
        return SharePlayUIState(state: .waitingForFriend, localRole: .host)
    }

    private var showsPlayWithFriendsOnMenu: Bool {
        #if os(iOS) || os(macOS)
        configuration.fixture.showsPlayWithFriendsOnMenu
        #else
        false
        #endif
    }

    private func presentSettingsSheetFromMenu() {
        isSettingsSheetPresented = true
    }

    private func handleMenuBackgroundGameplayReady() {
        isGameplayReady = true
        #if os(macOS)
        presentSettingsSheetFromMenu()
        #endif
        updateCaptureReadiness()
    }

    private func handleMenuScreenshotReady() {
        isMenuReady = true
        updateCaptureReadiness()
    }

    private func handleGameplayLayoutReady() {
        isGameplayReady = true
        if configuration.fixture.presentsGameOverSheet {
            isGameOverSheetPresented = true
        }
        if configuration.fixture.presentsAchievementSheet {
            isAchievementSheetPresented = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                handleSheetLayoutReady()
            }
        }
        updateCaptureReadiness()
    }

    private func handleSheetLayoutReady() {
        isSheetReady = true
        updateCaptureReadiness()
    }

    private func updateCaptureReadiness() {
        let shouldBeReady: Bool
        if configuration.fixture.presentsMenu {
            shouldBeReady = isMenuReady
        } else if configuration.fixture.presentsSettingsSheet {
            #if os(macOS)
            shouldBeReady = isGameplayReady && isSheetReady
            #else
            shouldBeReady = isSheetReady
            #endif
        } else if configuration.fixture.presentsGameOverSheet || configuration.fixture.presentsAchievementSheet {
            shouldBeReady = isGameplayReady && isSheetReady
        } else {
            shouldBeReady = isGameplayReady
        }
        if isLayoutReady != shouldBeReady {
            isLayoutReady = shouldBeReady
        }
    }
}
