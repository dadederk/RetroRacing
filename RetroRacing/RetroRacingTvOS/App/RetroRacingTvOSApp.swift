import SwiftUI
import RetroRacingShared
import GameKit
import GameController
import GroupActivities

@main
struct RetroRacingTvOSApp: App {
    private let leaderboardConfiguration = LeaderboardConfigurationTvOS()
    private let authenticationPresenter = AuthenticationPresenterUniversal()
    private let gameCenterService: GameCenterService
    private let ratingService: RatingService
    private let themeManager: ThemeManager
    private let fontPreferenceStore: FontPreferenceStore
    private let hapticController: HapticFeedbackController
    private let highestScoreStore: HighestScoreStore
    private let achievementProgressService: AchievementProgressService
    private let achievementMetadataService: any AchievementMetadataService
    private let pendingLeaderboardScoreStore: any PendingLeaderboardScoreStore
    private let bestScoreSyncService: BestScoreSyncService
    private let playLimitService: PlayLimitService
    private let specialEventService: SpecialEventService
    private let storeKitService: StoreKitService
    private let controllerInputSource: SystemGameControllerInputSource
    private let sharePlayMatchService: any SharePlayMatchService
    private let groupStateObserver: GroupStateObserver
    @State private var shouldStartGame = false
    @State private var isMenuPresented = true
    @State private var sessionID = UUID()
    @State private var sharePlayUIState: SharePlayUIState = .idle
    @State private var isSharePlayGuidancePresented = false

    init() {
        AppBootstrap.configureAudioSession()
        AppBootstrap.configureGameCenterAccessPoint()
        let customFontAvailable = AppBootstrap.registerCustomFont()
        let userDefaults = InfrastructureDefaults.userDefaults
        SettingsPreferenceMigration.runIfNeeded(
            userDefaults: userDefaults,
            supportsHaptics: false
        )
        storeKitService = StoreKitService(userDefaults: userDefaults)
        let themeConfig = ThemePlatformConfig.configuration(
            for: .tvOS,
            experimentalThemes: DebugGameplayStorageKeys.experimentalThemeConfiguration(
                userDefaults: userDefaults,
                debugFeaturesAllowed: BuildConfiguration.shouldShowDebugFeatures,
                platform: .tvOS
            )
        )
        let configuredThemeManager = ThemeManager(
            configuration: themeConfig,
            userDefaults: userDefaults,
            hasPremiumAccess: storeKitService.hasPremiumAccessForGating
        )
        themeManager = configuredThemeManager
        fontPreferenceStore = FontPreferenceStore(userDefaults: userDefaults, customFontAvailable: customFontAvailable)
        hapticController = RetroRacingTvOSApp.makeHapticsController()
        let authenticateHandlerSetter: AuthenticateHandlerSetter? = BuildConfiguration.isRunningUITests
            ? { _ in }
            : { presenter in
                GKLocalPlayer.local.authenticateHandler = { viewController, error in
                    if let viewController {
                        presenter.presentAuthenticationUI(viewController)
                        return
                    }
                    NotificationCenter.default.post(
                        name: .GKPlayerAuthenticationDidChangeNotificationName,
                        object: error
                    )
                }
            }
        let leaderboardConfig = LeaderboardPlatformConfig(
            leaderboardID: leaderboardConfiguration.leaderboardID(
                for: GameDifficulty.currentSelection(from: userDefaults)
            ),
            authenticateHandlerSetter: authenticateHandlerSetter
        )
        pendingLeaderboardScoreStore = UserDefaultsPendingLeaderboardScoreStore(userDefaults: userDefaults)
        gameCenterService = GameCenterService(
            configuration: leaderboardConfiguration,
            friendSnapshotService: GameCenterFriendSnapshotService(
                configuration: .standard,
                avatarCache: GameCenterAvatarCache()
            ),
            authenticationPresenter: authenticationPresenter,
            authenticateHandlerSetter: leaderboardConfig.authenticateHandlerSetter,
            isDebugBuild: BuildConfiguration.isDebug,
            allowDebugScoreSubmission: false,
            pendingScoreStore: pendingLeaderboardScoreStore
        )
        ratingService = StoreReviewService(userDefaults: userDefaults, ratingProvider: RatingServiceProviderTvOS())
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

        BuildConfiguration.initializeTestFlightCheck()
        controllerInputSource = SystemGameControllerInputSource(
            platformConfig: .tvOS,
            userDefaults: userDefaults
        )
        sharePlayMatchService = GroupActivitiesSharePlayMatchService(
            difficultyProvider: { GameDifficulty.currentSelection(from: userDefaults) }
        )
        groupStateObserver = GroupStateObserver()
    }

    private static func makeMiamiGrandPrixEventService() -> SpecialEventService {
        DateRangeSpecialEventService.miamiGrandPrix2026
    }

    private static func makeHapticsController() -> HapticFeedbackController {
        NoOpHapticFeedbackController()
    }

    var body: some Scene {
        WindowGroup {
            ZStack {
                GameView(
                    leaderboardService: gameCenterService,
                    ratingService: ratingService,
                    theme: themeManager.currentTheme,
                    hapticController: hapticController,
                    supportsHapticFeedback: false,
                    fontPreferenceStore: fontPreferenceStore,
                    highestScoreStore: highestScoreStore,
                    achievementProgressService: achievementProgressService,
                    playLimitService: playLimitService,
                    specialEventService: specialEventService,
                    sharePlayMatchService: sharePlayMatchService,
                    sharePlayUIState: sharePlayUIState,
                    style: .tvOS,
                    inputAdapterFactory: RemoteInputAdapterFactory(),
                    controllerInputSource: controllerInputSource,
                    controlsDescriptionKey: "settings_controls_tvos",
                    shouldStartGame: shouldStartGame,
                    showMenuButton: true,
                    onFinishRequest: handleFinish,
                    isMenuOverlayPresented: $isMenuPresented
                )
                .id(sessionID)
                .accessibilityHidden(isMenuPresented)
                .allowsHitTesting(isMenuPresented == false)
                .disabled(isMenuPresented)

                if isMenuPresented {
                    MenuView(
                        leaderboardService: gameCenterService,
                        gameCenterService: gameCenterService,
                        ratingService: ratingService,
                        leaderboardConfiguration: leaderboardConfiguration,
                        authenticationPresenter: authenticationPresenter,
                        themeManager: themeManager,
                        fontPreferenceStore: fontPreferenceStore,
                        hapticController: hapticController,
                        supportsHapticFeedback: false,
                        highestScoreStore: highestScoreStore,
                        achievementProgressService: achievementProgressService,
                        playLimitService: playLimitService,
                        specialEventService: specialEventService,
                        style: .tvOS,
                        settingsStyle: .tvOS,
                        gameViewStyle: .tvOS,
                        controlsDescriptionKey: "settings_controls_tvos",
                        showRateButton: false,
                        inputAdapterFactory: RemoteInputAdapterFactory(),
                        onPlayRequest: handlePlayRequest,
                        onPlayWithFriendsRequest: handlePlayWithFriendsRequest,
                        isSharePlayActive: sharePlayUIState.state.isActive
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.ignoresSafeArea())
                    .zIndex(1)
                }
            }
            .animation(nil, value: isMenuPresented)
            .onChange(of: isMenuPresented) { _, isPresented in
                if isPresented == false {
                    handleMenuDismissed()
                }
            }
            .environment(storeKitService)
            .achievementMetadataService(achievementMetadataService)
            .sharePlayMatchService(sharePlayMatchService)
            .alert(
                GameLocalizedStrings.string("menu_play_with_friends"),
                isPresented: $isSharePlayGuidancePresented
            ) {
                Button(GameLocalizedStrings.string("ok"), role: .cancel) {}
            } message: {
                Text(GameLocalizedStrings.string("tvos_shareplay_facetime_required"))
            }
            .task {
                await storeKitService.loadProducts()
                await bestScoreSyncService.syncIfPossible()
            }
            .task {
                await sharePlayMatchService.setStateChangeHandler { uiState in
                    await MainActor.run {
                        handleSharePlayStateChanged(uiState)
                    }
                }
                await sharePlayMatchService.observeIncomingSessions()
            }
            .onReceive(NotificationCenter.default.publisher(for: .GKPlayerAuthenticationDidChangeNotificationName)) { _ in
                Task {
                    await bestScoreSyncService.syncIfPossible()
                    achievementProgressService.replayAchievedAchievements()
                    gameCenterService.flushPendingScoresIfPossible()
                    await achievementMetadataService.invalidate()
                }
            }
        }
    }

    private func handlePlayRequest() {
        let previousSession = applyMenuSessionTransition(
            using: { MenuSessionTransitionPolicy.stateAfterPlayRequest(from: $0) }
        )
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SESSION_PLAY_REQUEST",
            outcome: .requested,
            fields: [
                .string("fromSession", AppLog.shortID(previousSession)),
                .string("toSession", AppLog.shortID(sessionID))
            ]
        )
    }

    private func handlePlayWithFriendsRequest() {
        guard sharePlayUIState.state.isActive == false else { return }
        guard groupStateObserver.isEligibleForGroupSession else {
            isSharePlayGuidancePresented = true
            return
        }

        Task { @concurrent [sharePlayMatchService] in
            guard await sharePlayMatchService.prepareHostActivation() else { return }
            _ = await sharePlayMatchService.activatePendingHostSession(
                reason: .eligibleMenuRequest
            )
        }
    }

    private func handleSharePlayStateChanged(_ newValue: SharePlayUIState) {
        let wasIdle = sharePlayUIState.state == .idle
        sharePlayUIState = newValue
        guard wasIdle, newValue.state.isActive, isMenuPresented else { return }
        _ = applyMenuSessionTransition(
            using: { MenuSessionTransitionPolicy.stateAfterPlayRequest(from: $0) }
        )
    }

    private func handleMenuDismissed() {
        AppLog.info(AppLog.lifecycle + AppLog.game, "MENU_DISMISS", outcome: .completed)
    }

    private func handleFinish() {
        let previousSession = applyMenuSessionTransition(
            using: { MenuSessionTransitionPolicy.stateAfterFinishRequest(from: $0) }
        )
        AppLog.info(
            AppLog.lifecycle + AppLog.game,
            "SESSION_FINISH_REQUEST",
            outcome: .requested,
            fields: [
                .string("fromSession", AppLog.shortID(previousSession)),
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
}
