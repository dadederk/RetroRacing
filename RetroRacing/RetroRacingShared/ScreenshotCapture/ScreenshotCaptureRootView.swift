//
//  ScreenshotCaptureRootView.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 23/07/2026.
//

import SwiftUI

public struct ScreenshotCaptureDependencies {
    let leaderboardService: LeaderboardService
    let gameCenterService: GameCenterService
    let leaderboardConfiguration: LeaderboardConfiguration
    let authenticationPresenter: AuthenticationPresenter
    let ratingService: RatingService
    let themeManager: ThemeManager
    let appIconService: AppIconService
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

    public init(
        leaderboardService: LeaderboardService,
        gameCenterService: GameCenterService,
        leaderboardConfiguration: LeaderboardConfiguration,
        authenticationPresenter: AuthenticationPresenter,
        ratingService: RatingService,
        themeManager: ThemeManager,
        appIconService: AppIconService,
        fontPreferenceStore: FontPreferenceStore,
        screenshotFontPreferenceStore: FontPreferenceStore,
        hapticController: HapticFeedbackController,
        supportsHapticFeedback: Bool,
        highestScoreStore: HighestScoreStore,
        achievementProgressService: AchievementProgressService,
        playLimitService: PlayLimitService,
        specialEventService: SpecialEventService,
        sharePlayMatchService: any SharePlayMatchService,
        controllerInputSource: any GameControllerInputSource,
        controlsDescriptionKey: String,
        settingsPreviewDependencies: SettingsPreviewDependencies
    ) {
        self.leaderboardService = leaderboardService
        self.gameCenterService = gameCenterService
        self.leaderboardConfiguration = leaderboardConfiguration
        self.authenticationPresenter = authenticationPresenter
        self.ratingService = ratingService
        self.themeManager = themeManager
        self.appIconService = appIconService
        self.fontPreferenceStore = fontPreferenceStore
        self.screenshotFontPreferenceStore = screenshotFontPreferenceStore
        self.hapticController = hapticController
        self.supportsHapticFeedback = supportsHapticFeedback
        self.highestScoreStore = highestScoreStore
        self.achievementProgressService = achievementProgressService
        self.playLimitService = playLimitService
        self.specialEventService = specialEventService
        self.sharePlayMatchService = sharePlayMatchService
        self.controllerInputSource = controllerInputSource
        self.controlsDescriptionKey = controlsDescriptionKey
        self.settingsPreviewDependencies = settingsPreviewDependencies
    }
}

public struct ScreenshotCaptureRootView: View {
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

    public init(
        configuration: ScreenshotCaptureConfiguration,
        dependencies: ScreenshotCaptureDependencies
    ) {
        self.configuration = configuration
        self.dependencies = dependencies
    }

    public var body: some View {
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
                    settingsSheet(focus: focus)
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
    private func settingsSheet(focus: ScreenshotSettingsFocus) -> some View {
        if isAppleTVCapture {
            settingsView(focus: focus)
        } else {
            settingsView(focus: focus)
                #if os(iOS)
                .presentationBackground(Color(uiColor: .systemGroupedBackground))
                #endif
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
        if isAppleTVCapture, configuration.fixture.presentsSettingsSheet {
            appleTVSettingsCaptureContent
        } else if isAppleTVCapture, configuration.fixture.presentsGameOverSheet {
            appleTVGameOverCaptureContent
        } else if isAppleTVCapture, configuration.fixture.presentsAchievementSheet {
            appleTVAchievementCaptureContent
        } else if configuration.fixture.presentsMenu {
            freeUserMenuCaptureView
        } else if configuration.fixture.presentsSettingsSheet {
            settingsSlideCaptureContent
        } else {
            gameplayCaptureView
        }
    }

    private var appleTVSettingsCaptureContent: some View {
        Group {
            if let settingsFocus {
                settingsSheet(focus: settingsFocus)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }

    private var appleTVGameOverCaptureContent: some View {
        ZStack {
            gameplayCaptureView
            appleTVCaptureScrim
            appleTVCaptureModal {
                gameOverView
            }
        }
    }

    private var appleTVAchievementCaptureContent: some View {
        ZStack {
            gameplayCaptureView
            appleTVCaptureScrim
            appleTVCaptureModal {
                AchievementUnlockView(
                    achievementID: .controlVoiceOver,
                    onDone: {}
                )
                .fontPreferenceStore(dependencies.screenshotFontPreferenceStore)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.75) {
                        handleSheetLayoutReady()
                    }
                }
            }
        }
    }

    private var appleTVCaptureScrim: some View {
        Color.black
            .opacity(0.55)
            .ignoresSafeArea()
    }

    private func appleTVCaptureModal<Content: View>(
        @ViewBuilder content: () -> Content
    ) -> some View {
        content()
            .frame(width: 1_200, height: 860)
            .background(.regularMaterial)
            .clipShape(.rect(cornerRadius: 36))
            .shadow(color: .black.opacity(0.45), radius: 40, y: 18)
            .accessibilityElement(children: .contain)
            .accessibilityAddTraits(.isModal)
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
            appIconService: dependencies.appIconService,
            fontPreferenceStore: dependencies.screenshotFontPreferenceStore,
            hapticController: dependencies.hapticController,
            supportsHapticFeedback: dependencies.supportsHapticFeedback,
            highestScoreStore: dependencies.highestScoreStore,
            achievementProgressService: dependencies.achievementProgressService,
            playLimitService: dependencies.playLimitService,
            specialEventService: dependencies.specialEventService,
            style: menuStyle,
            settingsStyle: settingsStyle,
            gameViewStyle: gameViewStyle,
            controlsDescriptionKey: dependencies.controlsDescriptionKey,
            showRateButton: isAppleTVCapture == false,
            inputAdapterFactory: inputAdapterFactory,
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

    @ViewBuilder
    private func gameplayCaptureView(
        layout: GameScreenshotLayout,
        readinessIdentifier: String?,
        onLayoutReady: @escaping () -> Void
    ) -> some View {
        if isAppleTVCapture {
            configuredGameplayCaptureView(
                layout: layout,
                readinessIdentifier: readinessIdentifier,
                onLayoutReady: onLayoutReady
            )
        } else {
            NavigationStack {
                configuredGameplayCaptureView(
                    layout: layout,
                    readinessIdentifier: readinessIdentifier,
                    onLayoutReady: onLayoutReady
                )
            }
        }
    }

    private func configuredGameplayCaptureView(
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
            style: gameViewStyle,
            inputAdapterFactory: inputAdapterFactory,
            controllerInputSource: dependencies.controllerInputSource,
            controlsDescriptionKey: dependencies.controlsDescriptionKey,
            shouldStartGame: true,
            showMenuButton: isAppleTVCapture == false,
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
            appIconService: dependencies.appIconService,
            fontPreferenceStore: dependencies.screenshotFontPreferenceStore,
            supportsHapticFeedback: dependencies.supportsHapticFeedback,
            hapticController: dependencies.hapticController,
            audioCueTutorialPreviewPlayer: dependencies.settingsPreviewDependencies.audioCueTutorialPreviewPlayer,
            speedWarningFeedbackPreviewPlayer: dependencies.settingsPreviewDependencies.speedWarningFeedbackPreviewPlayer,
            controlsDescriptionKey: dependencies.controlsDescriptionKey,
            style: settingsStyle,
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

    private var isAppleTVCapture: Bool {
        switch ScreenshotCaptureConfiguration.capturePlatform?.lowercased() {
        case "appletv", "tv", "tvos":
            true
        default:
            false
        }
    }

    private var menuStyle: MenuViewStyle {
        isAppleTVCapture ? .tvOS : .universal
    }

    private var settingsStyle: SettingsViewStyle {
        isAppleTVCapture ? .tvOS : .universal
    }

    private var gameViewStyle: GameViewStyle {
        isAppleTVCapture ? .tvOS : .universal
    }

    private var inputAdapterFactory: any GameInputAdapterFactory {
        isAppleTVCapture ? RemoteInputAdapterFactory() : TouchInputAdapterFactory()
    }

    private var sharePlayUIState: SharePlayUIState {
        guard configuration.fixture.usesSharePlayWaitingOverlay else { return .idle }
        return SharePlayUIState(state: .waitingForFriend, localRole: .host)
    }

    private var showsPlayWithFriendsOnMenu: Bool {
        configuration.fixture.showsPlayWithFriendsOnMenu
    }

    private func presentSettingsSheetFromMenu() {
        guard isAppleTVCapture == false else { return }
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
        if configuration.fixture.presentsGameOverSheet, isAppleTVCapture == false {
            isGameOverSheetPresented = true
        }
        if configuration.fixture.presentsAchievementSheet, isAppleTVCapture == false {
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
