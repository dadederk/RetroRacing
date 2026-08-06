import SwiftUI
import RetroRacingShared
import GameKit
import GameController

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
    @State private var shouldStartGame = false
    @State private var isMenuPresented = true
    @State private var sessionID = UUID()

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
                        onPlayRequest: handlePlayRequest
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
            .task {
                await storeKitService.loadProducts()
                await bestScoreSyncService.syncIfPossible()
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
