//
//  RetroRacingApp.swift
//  RetroRacingUniversal
//
//  Created by Dani Devesa on 03/02/2026.
//

import SwiftUI
import RetroRacingShared
import GameKit
#if canImport(UIKit)
import UIKit
#endif
#if canImport(UIKit) && !os(tvOS) && !os(watchOS)
import CoreHaptics
#endif
#if canImport(GroupActivities) && (os(iOS) || os(macOS))
import GroupActivities
#endif
import GameController
#if os(macOS)
import AppKit
#endif

/// App entry point assembling shared services and presenting the universal menu scene.
@main
struct RetroRacingApp: App {
    @Environment(\.scenePhase) private var scenePhase
    #if os(macOS)
    @NSApplicationDelegateAdaptor(MacScreenshotCaptureAppDelegate.self) private var macAppDelegate
    #endif

    private let leaderboardConfiguration: LeaderboardConfiguration
    #if canImport(UIKit)
    private let authenticationPresenter = AuthenticationPresenterUniversal()
    #else
    private let authenticationPresenter = NoOpAuthenticationPresenter()
    #endif
    private let gameCenterService: GameCenterService
    private let screenshotGameCenterService: GameCenterService
    private let ratingService: RatingService
    private let themeManager: ThemeManager
    private let fontPreferenceStore: FontPreferenceStore
    private let hapticController: HapticFeedbackController
    private let supportsHapticFeedback: Bool
    private let highestScoreStore: HighestScoreStore
    private let achievementProgressService: AchievementProgressService
    private let achievementMetadataService: any AchievementMetadataService
    private let pendingLeaderboardScoreStore: any PendingLeaderboardScoreStore
    private let bestScoreSyncService: BestScoreSyncService
    private let watchRelayIngestionService: WatchRelayedBestScoreIngestionService?
    /// Retained so WCSession delegate callbacks remain active.
    private let watchRelayReceiver: WatchBestScoreRelayReceiver?
    private let playLimitService: PlayLimitService
    private let specialEventService: SpecialEventService
    private let storeKitService: StoreKitService
    private let sharePlayMatchService: any SharePlayMatchService
    private let controllerInputSource: SystemGameControllerInputSource
    private let controlsDescriptionKey: String
    @State private var isMenuPresented = true
    @State private var isSettingsPresented = false
    @State private var sharePlayActivationHandoffCoordinator: SharePlayActivationHandoffCoordinator
    /// Controls whether gameplay should be allowed to start for the current session.
    /// On initial launch and after Finish, this is false so that the SpriteKit
    /// scene is not created until the menu overlay is dismissed via Play.
    @State private var shouldStartGame = false
    @State private var sessionID = UUID()
    /// Mirrors `SharePlayMatchService` state. `GameViewModel` is recreated every play session,
    /// so this composition root owns the single long-lived state-change handler and pushes
    /// updates down into `GameView` via an explicit prop (see `SharePlayUIState`).
    @State private var sharePlayUIState: SharePlayUIState = .idle

    init() {
        ScreenshotCaptureLocaleCatalog.configureCaptureLocaleDefaultsForLaunch()
        #if os(macOS)
        if ScreenshotCaptureConfiguration.isCaptureModeEnabled {
            NSApplication.shared.setActivationPolicy(.regular)
        }
        ScreenshotCaptureLaunchDiagnostics.writeAppLaunchSnapshot(
            stagingDirectory: ScreenshotCaptureConfiguration.current?.stagingDirectory
        )
        #endif
        ScreenshotCaptureAppearance.applySystemInterfaceStyleIfNeeded()
        AppBootstrap.configureAudioSession()
        if ScreenshotCaptureConfiguration.isCaptureModeEnabled == false {
            AppBootstrap.configureGameCenterAccessPoint()
        }
        let customFontAvailable = AppBootstrap.registerCustomFont()
        let userDefaults = InfrastructureDefaults.userDefaults
        let supportsHaptics = Self.deviceSupportsHapticFeedback()
        SettingsPreferenceMigration.runIfNeeded(
            userDefaults: userDefaults,
            supportsHaptics: supportsHaptics
        )
        storeKitService = StoreKitService(userDefaults: userDefaults)
        pendingLeaderboardScoreStore = UserDefaultsPendingLeaderboardScoreStore(userDefaults: userDefaults)
        #if os(macOS)
        leaderboardConfiguration = LeaderboardConfigurationMac()
        controlsDescriptionKey = "settings_controls_macos"
        #elseif canImport(UIKit)
        controlsDescriptionKey = "settings_controls_ios"
        if UIDevice.current.userInterfaceIdiom == .pad {
            leaderboardConfiguration = LeaderboardConfigurationIPad()
        } else {
            leaderboardConfiguration = LeaderboardConfigurationUniversal()
        }
        #else
        leaderboardConfiguration = LeaderboardConfigurationUniversal()
        controlsDescriptionKey = "settings_controls_ios"
        #endif
        let leaderboardPlatformConfig = LeaderboardPlatformConfig(
            leaderboardID: leaderboardConfiguration.leaderboardID(
                for: GameDifficulty.currentSelection(from: userDefaults)
            ),
            authenticateHandlerSetter: { presenter in
                GKLocalPlayer.local.authenticateHandler = { viewController, error in
                    if let viewController = viewController {
                        presenter.presentAuthenticationUI(viewController)
                        return
                    }
                    // When Game Center finishes (success or failure) without UI, notify listeners so they can refresh state.
                    NotificationCenter.default.post(name: .GKPlayerAuthenticationDidChangeNotificationName, object: error)
                }
            }
        )
        gameCenterService = GameCenterService(
            configuration: leaderboardConfiguration,
            friendSnapshotService: GameCenterFriendSnapshotService(
                configuration: .standard,
                avatarCache: GameCenterAvatarCache()
            ),
            authenticationPresenter: authenticationPresenter,
            authenticateHandlerSetter: leaderboardPlatformConfig.authenticateHandlerSetter,
            isDebugBuild: BuildConfiguration.isDebug,
            allowDebugScoreSubmission: true,
            pendingScoreStore: pendingLeaderboardScoreStore
        )
        screenshotGameCenterService = Self.makeScreenshotGameCenterService(
            leaderboardConfiguration: leaderboardConfiguration
        )
        #if canImport(UIKit)
        ratingService = StoreReviewService(userDefaults: userDefaults, ratingProvider: RatingServiceProviderUniversal())
        #else
        ratingService = StoreReviewService(userDefaults: userDefaults, ratingProvider: RatingServiceProviderMac())
        #endif
        #if os(macOS)
        let themeConfig = ThemePlatformConfig.macOS
        #elseif canImport(UIKit)
        let themeConfig = UIDevice.current.userInterfaceIdiom == .pad
            ? ThemePlatformConfig.iPad
            : ThemePlatformConfig.iPhone
        #else
        let themeConfig = ThemePlatformConfig.iPhone
        #endif
        let themeUserDefaults = ScreenshotCaptureConfiguration.isCaptureModeEnabled
            ? ScreenshotCaptureThemePolicy.makeCaptureUserDefaults(
                platform: ScreenshotCaptureConfiguration.capturePlatform
            ) ?? userDefaults
            : userDefaults
        let configuredThemeManager = ThemeManager(
            configuration: themeConfig,
            userDefaults: themeUserDefaults,
            hasPremiumAccess: storeKitService.hasPremiumAccessForGating
        )
        themeManager = configuredThemeManager
        fontPreferenceStore = FontPreferenceStore(userDefaults: userDefaults, customFontAvailable: customFontAvailable)
        let hapticsConfig = HapticsPlatformConfig(
            supportsHaptics: supportsHaptics,
            controllerProvider: { Self.makeHapticsController(userDefaults: userDefaults) }
        )
        hapticController = hapticsConfig.controllerProvider()
        supportsHapticFeedback = hapticsConfig.supportsHaptics
        highestScoreStore = UserDefaultsHighestScoreStore(userDefaults: userDefaults)
        achievementProgressService = LocalAchievementProgressService(
            store: UserDefaultsAchievementProgressStore(userDefaults: userDefaults),
            highestScoreStore: highestScoreStore,
            reporter: GameCenterAchievementProgressReporter()
        )
        achievementProgressService.performInitialBackfillIfNeeded()
        achievementProgressService.replayAchievedAchievements()
        achievementMetadataService = GameCenterAchievementMetadataService()
        bestScoreSyncService = BestScoreSyncService(
            leaderboardService: gameCenterService,
            highestScoreStore: highestScoreStore,
            difficultyProvider: {
                GameDifficulty.currentSelection(from: userDefaults)
            }
        )
        #if os(iOS)
        let watchRelayLeaderboardService = GameCenterService(
            configuration: LeaderboardConfigurationWatchOS(),
            friendSnapshotService: GameCenterFriendSnapshotService(
                configuration: .standard,
                avatarCache: GameCenterAvatarCache()
            ),
            authenticationPresenter: nil,
            authenticateHandlerSetter: nil,
            isDebugBuild: BuildConfiguration.isDebug,
            allowDebugScoreSubmission: true
        )
        let watchRelayPendingStore = UserDefaultsRelayedWatchBestScoreStore(
            userDefaults: userDefaults,
            keyPrefix: "watchRelayPendingBestScore"
        )
        let relayIngestionService = WatchRelayedBestScoreIngestionService(
            leaderboardService: watchRelayLeaderboardService,
            pendingStore: watchRelayPendingStore
        )
        watchRelayIngestionService = relayIngestionService
        let relayReceiver = WatchBestScoreRelayReceiver(ingestionService: relayIngestionService)
        relayReceiver.activate()
        watchRelayReceiver = relayReceiver
        #else
        watchRelayIngestionService = nil
        watchRelayReceiver = nil
        #endif

        BuildConfiguration.initializeTestFlightCheck()
        let playLimit = UserDefaultsPlayLimitService(userDefaults: userDefaults)
        playLimitService = playLimit
        storeKitService.onEntitlementsUpdated = { isPremium in
            if isPremium {
                playLimit.unlockUnlimitedAccess()
            } else {
                playLimit.clearUnlimitedAccess()
            }
        }
        storeKitService.onPremiumAccessForGatingUpdated = { hasPremiumAccessForGating in
            configuredThemeManager.syncPremiumAccess(hasPremiumAccessForGating)
        }
        specialEventService = Self.makeMiamiGrandPrixEventService()
        #if canImport(GroupActivities) && (os(iOS) || os(macOS))
        let groupStateObserver = GroupStateObserver()
        let sharePlayService = GroupActivitiesSharePlayMatchService(
            difficultyProvider: { GameDifficulty.currentSelection(from: userDefaults) }
        )
        sharePlayMatchService = sharePlayService
        _sharePlayActivationHandoffCoordinator = State(
            initialValue: SharePlayActivationHandoffCoordinator(
                sharePlayMatchService: sharePlayService,
                isSharePlayAvailable: true,
                isEligibleForGroupSession: {
                    groupStateObserver.isEligibleForGroupSession
                }
            )
        )
        #else
        let sharePlayService = NoOpSharePlayMatchService()
        sharePlayMatchService = sharePlayService
        _sharePlayActivationHandoffCoordinator = State(
            initialValue: SharePlayActivationHandoffCoordinator(
                sharePlayMatchService: sharePlayService,
                isSharePlayAvailable: false,
                isEligibleForGroupSession: { false }
            )
        )
        #endif
        controllerInputSource = SystemGameControllerInputSource(
            platformConfig: .standard,
            userDefaults: userDefaults
        )
    }

    private static func makeMiamiGrandPrixEventService() -> SpecialEventService {
        DateRangeSpecialEventService.miamiGrandPrix2026
    }

    /// Returns true when the device has haptic hardware. Used to show/hide haptic setting (configuration injection).
    private static func deviceSupportsHapticFeedback() -> Bool {
        #if canImport(UIKit) && !os(tvOS)
        return CHHapticEngine.capabilitiesForHardware().supportsHaptics
        #else
        return false
        #endif
    }

    private static func makeHapticsController(userDefaults: UserDefaults) -> HapticFeedbackController {
        #if canImport(UIKit) && !os(tvOS)
        return UIKitHapticFeedbackController(userDefaults: userDefaults)
        #else
        return NoOpHapticFeedbackController()
        #endif
    }

    @discardableResult
    private func handleUniversalLink(_ url: URL, source: String) -> Bool {
        let normalizedPath = url.path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let isRetroRapidOpenLink = url.host == "accessibilityupto11.com" && normalizedPath == "apps/retrorapid/open"

        if isRetroRapidOpenLink {
            AppLog.info(
                AppLog.lifecycle + AppLog.game,
                "UNIVERSAL_LINK",
                outcome: .succeeded,
                fields: [
                    .string("source", source),
                    .string("url", AppLog.redactedURL(url))
                ]
            )
            return true
        }

        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "UNIVERSAL_LINK",
            outcome: .ignored,
            fields: [
                .reason("unsupported_path"),
                .string("source", source),
                .string("url", AppLog.redactedURL(url))
            ]
        )
        return false
    }

    var body: some Scene {
        #if os(macOS)
        appWindowGroup
            .commands {
                CommandGroup(replacing: .appSettings) {
                    Button(GameLocalizedStrings.string("settings")) {
                        handleSettingsRequest()
                    }
                    .keyboardShortcut(",", modifiers: .command)
                }
            }
        #else
        appWindowGroup
        #endif
    }

    private var appWindowGroup: some Scene {
        WindowGroup {
            appRootContainer
            .transaction { transaction in
                if ScreenshotCaptureConfiguration.current != nil {
                    transaction.disablesAnimations = true
                }
            }
        }
        #if os(macOS)
        .defaultSize(ScreenshotCaptureWindowConfiguration.macLandscapeContentSize)
        .defaultLaunchBehavior(
            ScreenshotCaptureConfiguration.isCaptureModeEnabled ? .presented : .automatic
        )
        #endif
    }

    private var resolvedAchievementMetadataService: any AchievementMetadataService {
        if ScreenshotCaptureConfiguration.isCaptureModeEnabled {
            // Use ASC-aligned local strings during capture; live Game Center metadata is often English.
            return NoOpAchievementMetadataService()
        }
        return achievementMetadataService
    }

    @ViewBuilder
    private var appRootContainer: some View {
        let configuredRoot = rootView
            .environment(storeKitService)
            .achievementMetadataService(resolvedAchievementMetadataService)
            .sharePlayMatchService(sharePlayMatchService)
            .task {
                guard ScreenshotCaptureConfiguration.isCaptureModeEnabled == false else { return }
                await storeKitService.loadProducts()
                await bestScoreSyncService.syncIfPossible()
                await watchRelayIngestionService?.flushPendingIfPossible(trigger: .appLifecycle)
            }
            .task {
                guard ScreenshotCaptureConfiguration.isCaptureModeEnabled == false else { return }
                await sharePlayMatchService.setStateChangeHandler { uiState in
                    await MainActor.run {
                        handleSharePlayStateChanged(uiState)
                    }
                }
                await sharePlayMatchService.observeIncomingSessions()
            }
            .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { userActivity in
                guard let url = userActivity.webpageURL else { return }
                handleUniversalLink(url, source: "SwiftUI.onContinueUserActivity")
            }
            .onOpenURL { url in
                handleUniversalLink(url, source: "SwiftUI.onOpenURL")
            }
            .onReceive(NotificationCenter.default.publisher(for: .GKPlayerAuthenticationDidChangeNotificationName)) { _ in
                guard ScreenshotCaptureConfiguration.isCaptureModeEnabled == false else { return }
                Task {
                    await bestScoreSyncService.syncIfPossible()
                    await watchRelayIngestionService?.flushPendingIfPossible(trigger: .gameCenterAuthChanged)
                    achievementProgressService.replayAchievedAchievements()
                    gameCenterService.flushPendingScoresIfPossible()
                    await achievementMetadataService.invalidate()
                }
            }
            .onChange(of: scenePhase) { _, newValue in
                guard newValue == .active else { return }
                #if os(macOS)
                if ScreenshotCaptureConfiguration.current != nil {
                    ScreenshotCaptureMacWindowLayout.applyLandscapeCaptureSize()
                }
                #endif
                guard ScreenshotCaptureConfiguration.isCaptureModeEnabled == false else { return }
                Task {
                    await watchRelayIngestionService?.flushPendingIfPossible(trigger: .appLifecycle)
                }
            }

        if ScreenshotCaptureConfiguration.current != nil {
            configuredRoot
        } else {
            NavigationStack {
                configuredRoot
            }
        }
    }

    @ViewBuilder
    private var rootView: some View {
        if let screenshotConfiguration = ScreenshotCaptureConfiguration.current {
            screenshotCaptureView(for: screenshotConfiguration)
        } else {
            normalRootView
        }
    }

    @ViewBuilder
    private var normalRootView: some View {
        #if os(iOS) || os(tvOS)
        gameView
            .navigationBarTitleDisplayMode(.inline)
            .fullScreenCover(isPresented: $isMenuPresented, onDismiss: handleMenuDismissed) {
                menuView
            }
            .animation(nil, value: isMenuPresented)
        #else
        gameView
            .frame(minWidth: 820, minHeight: 620)
            .accessibilityHidden(isMenuPresented)
            .overlay {
                if isMenuPresented {
                    menuOverlayView
                }
            }
            .sheet(isPresented: $isSettingsPresented) {
                settingsSheetView
            }
            .animation(nil, value: isMenuPresented)
            .animation(nil, value: isSettingsPresented)
        #endif
    }

    private func screenshotCaptureView(for configuration: ScreenshotCaptureConfiguration) -> some View {
        ScreenshotCaptureRootView(
            configuration: configuration,
            dependencies: ScreenshotCaptureDependencies(
                leaderboardService: screenshotGameCenterService,
                gameCenterService: screenshotGameCenterService,
                leaderboardConfiguration: leaderboardConfiguration,
                authenticationPresenter: authenticationPresenter,
                ratingService: ratingService,
                themeManager: themeManager,
                fontPreferenceStore: fontPreferenceStore,
                screenshotFontPreferenceStore: makeScreenshotFontPreferenceStore(),
                hapticController: hapticController,
                supportsHapticFeedback: supportsHapticFeedback,
                highestScoreStore: highestScoreStore,
                achievementProgressService: achievementProgressService,
                playLimitService: playLimitService,
                specialEventService: specialEventService,
                sharePlayMatchService: sharePlayMatchService,
                controllerInputSource: controllerInputSource,
                controlsDescriptionKey: controlsDescriptionKey,
                settingsPreviewDependencies: settingsPreviewDependencyFactory.make(
                    hapticController: hapticController
                )
            )
        )
    }

    private static func makeScreenshotGameCenterService(
        leaderboardConfiguration: LeaderboardConfiguration
    ) -> GameCenterService {
        GameCenterService(
            configuration: leaderboardConfiguration,
            friendSnapshotService: ScreenshotNoOpFriendSnapshotService(),
            authenticationPresenter: nil,
            authenticateHandlerSetter: nil,
            isDebugBuild: true,
            allowDebugScoreSubmission: false,
            isAuthenticatedProvider: { false },
            pendingScoreStore: nil
        )
    }

    /// Shared game view used across platforms.
    private var gameView: some View {
        GameView(
            leaderboardService: gameCenterService,
            ratingService: ratingService,
            theme: themeManager.currentTheme,
            hapticController: hapticController,
            supportsHapticFeedback: supportsHapticFeedback,
            fontPreferenceStore: fontPreferenceStore,
            highestScoreStore: highestScoreStore,
            achievementProgressService: achievementProgressService,
            playLimitService: playLimitService,
            specialEventService: specialEventService,
            sharePlayMatchService: sharePlayMatchService,
            sharePlayUIState: sharePlayUIState,
            style: .universal,
            inputAdapterFactory: TouchInputAdapterFactory(),
            controllerInputSource: controllerInputSource,
            controlsDescriptionKey: controlsDescriptionKey,
            shouldStartGame: shouldStartGame,
            showMenuButton: true,
            onFinishRequest: handleFinish,
            onMenuRequest: handleMenuRequest,
            onPlayRequest: handlePlayRequest,
            isMenuOverlayPresented: gameOverlayPauseBinding
        )
        .id(sessionID)
        .navigationTitle("")
    }

    /// Shared menu view presented on top of the game.
    private var menuView: some View {
        #if os(macOS)
        return MenuView(
            leaderboardService: gameCenterService,
            gameCenterService: gameCenterService,
            ratingService: ratingService,
            leaderboardConfiguration: leaderboardConfiguration,
            authenticationPresenter: authenticationPresenter,
            themeManager: themeManager,
            fontPreferenceStore: fontPreferenceStore,
            hapticController: hapticController,
            supportsHapticFeedback: supportsHapticFeedback,
            highestScoreStore: highestScoreStore,
            achievementProgressService: achievementProgressService,
            playLimitService: playLimitService,
            specialEventService: specialEventService,
            style: .universal,
            settingsStyle: .universal,
            gameViewStyle: .universal,
            controlsDescriptionKey: controlsDescriptionKey,
            showRateButton: true,
            inputAdapterFactory: TouchInputAdapterFactory(),
            onPlayRequest: handlePlayRequest,
            onSettingsRequest: handleSettingsRequest,
            onPlayWithFriendsRequest: handlePlayWithFriendsRequest,
            isSharePlayActive: sharePlayUIState.state.isActive
        )
        .interactiveDismissDisabled(true)
        #if canImport(GroupActivities) && os(macOS)
        .background {
            if let sharePlaySharingPresentation = sharePlayActivationHandoffCoordinator.sharingPresentation {
                SharePlayActivitySharingPresenter(
                    presentationID: sharePlaySharingPresentation.id,
                    onSucceeded: handleSharePlaySharingSucceeded,
                    onUserDismissed: handleSharePlaySharingUserDismissed
                )
                    .frame(width: 0, height: 0)
                    .id(sharePlaySharingPresentation.id)
                    .accessibilityHidden(true)
            }
        }
        #endif
        #else
        return MenuView(
            leaderboardService: gameCenterService,
            gameCenterService: gameCenterService,
            ratingService: ratingService,
            leaderboardConfiguration: leaderboardConfiguration,
            authenticationPresenter: authenticationPresenter,
            themeManager: themeManager,
            fontPreferenceStore: fontPreferenceStore,
            hapticController: hapticController,
            supportsHapticFeedback: supportsHapticFeedback,
            highestScoreStore: highestScoreStore,
            achievementProgressService: achievementProgressService,
            playLimitService: playLimitService,
            specialEventService: specialEventService,
            style: .universal,
            settingsStyle: .universal,
            gameViewStyle: .universal,
            controlsDescriptionKey: controlsDescriptionKey,
            showRateButton: true,
            inputAdapterFactory: TouchInputAdapterFactory(),
            onPlayRequest: handlePlayRequest,
            onPlayWithFriendsRequest: handlePlayWithFriendsRequest,
            isSharePlayActive: sharePlayUIState.state.isActive
        )
        .interactiveDismissDisabled(true)
        #if canImport(GroupActivities) && os(iOS)
        .background {
            if let sharePlaySharingPresentation = sharePlayActivationHandoffCoordinator.sharingPresentation {
                SharePlayActivitySharingPresenter(
                    presentationID: sharePlaySharingPresentation.id,
                    onSucceeded: handleSharePlaySharingSucceeded,
                    onUserDismissed: handleSharePlaySharingUserDismissed
                )
                    .frame(width: 0, height: 0)
                    .id(sharePlaySharingPresentation.id)
                    .accessibilityHidden(true)
            }
        }
        #endif
        #endif
    }

    #if os(macOS)
    private var menuOverlayView: some View {
        ZStack {
            Color.clear
                .background(.regularMaterial)
                .ignoresSafeArea()
            menuView
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .accessibilityElement(children: .contain)
        .accessibilityAddTraits(.isModal)
    }

    private var settingsSheetView: some View {
        let previewDependencies = settingsPreviewDependencyFactory.make(
            hapticController: hapticController
        )
        return SettingsView(
                themeManager: themeManager,
                fontPreferenceStore: fontPreferenceStore,
                supportsHapticFeedback: supportsHapticFeedback,
                hapticController: hapticController,
                audioCueTutorialPreviewPlayer: previewDependencies.audioCueTutorialPreviewPlayer,
                speedWarningFeedbackPreviewPlayer: previewDependencies.speedWarningFeedbackPreviewPlayer,
                controlsDescriptionKey: controlsDescriptionKey,
                style: .universal,
                achievementProgressService: achievementProgressService,
                isGameSessionInProgress: sharePlayUIState.state.isActive || (shouldStartGame && !isMenuPresented),
                playLimitService: playLimitService,
                specialEventService: specialEventService
            )
            .fontPreferenceStore(fontPreferenceStore)
            .settingsSheetStyle()
    }
    #endif

    private var gameOverlayPauseBinding: Binding<Bool> {
        #if os(macOS)
        Binding(
            get: { isMenuPresented || isSettingsPresented },
            set: { _ in }
        )
        #else
        $isMenuPresented
        #endif
    }

    private func handlePlayRequest() {
        let previousSessionID = applyMenuSessionTransition(
            using: { MenuSessionTransitionPolicy.stateAfterPlayRequest(from: $0) }
        )
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SESSION_PLAY_REQUEST",
            outcome: .requested,
            fields: [
                .string("fromSession", AppLog.shortID(previousSessionID)),
                .string("toSession", AppLog.shortID(sessionID))
            ]
        )
    }

    private func handlePlayWithFriendsRequest() {
        sharePlayActivationHandoffCoordinator.handlePlayWithFriendsRequest(
            currentState: sharePlayUIState.state
        )
    }

    /// Mirrors `SharePlayMatchService` state into `sharePlayUIState` for `GameView`, and — the
    /// first time a real session transitions away from idle — dismisses the menu and starts a game
    /// session, exactly like tapping Play, but without any daily play-limit/paywall check
    /// (SharePlay matches are always free). Covers host-initiated and system-activated
    /// (incoming) sessions identically, since both arrive via the same state-change handler.
    private func handleSharePlayStateChanged(_ newValue: SharePlayUIState) {
        let wasIdle = sharePlayUIState.state == .idle
        let previousState = sharePlayUIState.state
        logSharePlayUIStateChanged(from: previousState, to: newValue, wasIdle: wasIdle)
        if newValue.state != .idle {
            sharePlayActivationHandoffCoordinator.clearActivationRequest(reason: .sharePlayStateArrived)
        }
        sharePlayUIState = newValue
        if wasIdle, newValue.state != .idle {
            sharePlayActivationHandoffCoordinator.dismissSharingPresentation()
        }
        guard wasIdle, newValue.state != .idle, isMenuPresented else { return }
        let previousSessionID = applyMenuSessionTransition(
            using: { MenuSessionTransitionPolicy.stateAfterPlayRequest(from: $0) }
        )
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SHAREPLAY_SESSION_ENTRY",
            outcome: .started,
            fields: [
                .string("fromSession", AppLog.shortID(previousSessionID)),
                .string("toSession", AppLog.shortID(sessionID))
            ]
        )
    }

    private func logSharePlayUIStateChanged(
        from previousState: SharePlayMatchState,
        to newValue: SharePlayUIState,
        wasIdle: Bool
    ) {
        let fields: [AppLog.Field] = [
            .string("previousState", previousState.diagnosticName),
            .string("newState", newValue.state.diagnosticName),
            .string("role", newValue.localRole?.rawValue),
            .string("opponentName", AppLog.redactedPlayer(newValue.opponentDisplayName)),
            .bool("wasIdle", wasIdle),
            .bool("isMenuPresented", isMenuPresented),
            .bool("shouldStartGame", shouldStartGame),
            .string("session", AppLog.shortID(sessionID))
        ]
        if previousState.diagnosticName != newValue.state.diagnosticName {
            AppLog.info(AppLog.lifecycle + AppLog.game, "SHAREPLAY_UI_STATE", outcome: .completed, fields: fields)
        } else {
            AppLog.debug(AppLog.lifecycle + AppLog.game, "SHAREPLAY_UI_STATE", outcome: .completed, fields: fields)
        }
    }

    private func handleMenuDismissed() {
        sharePlayActivationHandoffCoordinator.dismissSharingPresentation()
        AppLog.info(AppLog.lifecycle + AppLog.game, "MENU_DISMISS", outcome: .completed)
    }

    private func handleSharePlaySharingSucceeded() {
        sharePlayActivationHandoffCoordinator.handleSharePlaySharingSucceeded(
            isSharePlayIdle: sharePlayUIState.state == .idle,
            isMenuPresented: isMenuPresented,
            shouldStartGame: shouldStartGame
        )
    }

    private func handleSharePlaySharingUserDismissed() {
        sharePlayActivationHandoffCoordinator.handleSharePlaySharingUserDismissed(
            isSharePlayIdle: sharePlayUIState.state == .idle
        )
    }

    private func handleFinish() {
        let previousSessionID = applyMenuSessionTransition(
            using: { MenuSessionTransitionPolicy.stateAfterFinishRequest(from: $0) }
        )
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SESSION_FINISH_REQUEST",
            outcome: .requested,
            fields: [
                .string("fromSession", AppLog.shortID(previousSessionID)),
                .string("toSession", AppLog.shortID(sessionID))
            ]
        )
    }

    private var currentMenuSessionState: MenuSessionState {
        MenuSessionState(
            shouldStartGame: shouldStartGame,
            isMenuPresented: isMenuPresented,
            sessionID: sessionID
        )
    }

    private func applyMenuSessionTransition(
        using transition: (MenuSessionState) -> MenuSessionState
    ) -> UUID {
        let previousSessionID = sessionID
        let nextState = transition(currentMenuSessionState)
        shouldStartGame = nextState.shouldStartGame
        isMenuPresented = nextState.isMenuPresented
        sessionID = nextState.sessionID
        return previousSessionID
    }

    private func handleMenuRequest() {
        AppLog.info(AppLog.lifecycle + AppLog.game, "MENU_REQUEST", outcome: .requested)
        isMenuPresented = true
    }

    private func handleSettingsRequest() {
        isSettingsPresented = true
    }

    private var settingsPreviewDependencyFactory: SettingsPreviewDependencyFactory {
        SettingsPreviewDependencyFactory(
            laneCuePlayerFactory: { PlatformFactories.makeLaneCuePlayer() },
            announcementPoster: AccessibilityAnnouncementPoster(),
            announcementTextProvider: {
                GameLocalizedStrings.string("speed_increase_announcement")
            },
            volumeProvider: {
                SoundEffectsVolumePreference.currentSelection(from: InfrastructureDefaults.userDefaults)
            }
        )
    }

    /// Isolated font store for screenshot capture so game-over and settings slides always use Press Start when bundled.
    private func makeScreenshotFontPreferenceStore() -> FontPreferenceStore {
        let store = FontPreferenceStore(
            userDefaults: UserDefaults(suiteName: "com.accessibilityUpTo11.RetroRacing.screenshot-font") ?? .standard,
            customFontAvailable: fontPreferenceStore.isCustomFontAvailable
        )
        if store.isCustomFontAvailable {
            store.currentStyle = .custom
        }
        return store
    }
}

private struct ScreenshotNoOpFriendSnapshotService: GameCenterFriendSnapshotServicing {
    func fetchFriendSnapshot(
        from leaderboard: GKLeaderboard,
        remoteBestScore: Int?
    ) async -> FriendLeaderboardSnapshot? {
        nil
    }
}
