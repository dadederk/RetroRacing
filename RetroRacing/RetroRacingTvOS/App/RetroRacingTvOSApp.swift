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
    private let storeKitService: StoreKitService
    private let controllerInputSource: SystemGameControllerInputSource
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
        let themeConfig = ThemePlatformConfig(
            defaultThemeID: "lcd",
            availableThemes: [LCDTheme(), PocketTheme()]
        )
        themeManager = ThemeManager(
            initialThemes: themeConfig.availableThemes,
            defaultThemeID: themeConfig.defaultThemeID,
            userDefaults: userDefaults
        )
        fontPreferenceStore = FontPreferenceStore(userDefaults: userDefaults, customFontAvailable: customFontAvailable)
        hapticController = RetroRacingTvOSApp.makeHapticsController()
        let leaderboardConfig = LeaderboardPlatformConfig(
            leaderboardID: leaderboardConfiguration.leaderboardID(
                for: GameDifficulty.currentSelection(from: userDefaults)
            ),
            authenticateHandlerSetter: { presenter in
                GKLocalPlayer.local.authenticateHandler = { viewController, error in
                    if let viewController {
                        presenter.presentAuthenticationUI(viewController)
                        return
                    }
                    NotificationCenter.default.post(name: .GKPlayerAuthenticationDidChangeNotificationName, object: error)
                }
            }
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
        playLimitService = UserDefaultsPlayLimitService(userDefaults: userDefaults)

        BuildConfiguration.initializeTestFlightCheck()
        controllerInputSource = SystemGameControllerInputSource(
            platformConfig: .tvOS,
            userDefaults: userDefaults
        )
    }

    private static func makeHapticsController() -> HapticFeedbackController {
        NoOpHapticFeedbackController()
    }

    var body: some Scene {
        WindowGroup {
            NavigationStack {
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
                    style: .tvOS,
                    inputAdapterFactory: RemoteInputAdapterFactory(),
                    controllerInputSource: controllerInputSource,
                    controlsDescriptionKey: "settings_controls_tvos",
                    showMenuButton: true,
                    onFinishRequest: handleFinish,
                    onMenuRequest: handleMenuRequest,
                    onPlayRequest: handleControllerPlayRequest,
                    isMenuOverlayPresented: $isMenuPresented
                )
                .id(sessionID)
                .fullScreenCover(isPresented: $isMenuPresented, onDismiss: handleMenuDismissed) {
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
                        style: .tvOS,
                        settingsStyle: .tvOS,
                        gameViewStyle: .tvOS,
                        controlsDescriptionKey: "settings_controls_tvos",
                        showRateButton: false,
                        inputAdapterFactory: RemoteInputAdapterFactory(),
                        onPlayRequest: handlePlayRequest
                    )
                    .interactiveDismissDisabled(true)
                }
                .animation(nil, value: isMenuPresented)
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
        AppLog.info(AppLog.game, "Play requested - starting new session and dismissing menu")
        sessionID = UUID()
        isMenuPresented = false
    }

    private func handleControllerPlayRequest() {
        // Controller Start/Menu pressed while menu is visible — dismiss without resetting session.
        AppLog.info(AppLog.game, "Controller play requested - resuming session and dismissing menu")
        isMenuPresented = false
    }

    private func handleMenuDismissed() {
        AppLog.info(AppLog.game, "Menu dismissed")
    }

    private func handleFinish() {
        AppLog.info(AppLog.game, "Finish requested - showing menu")
        isMenuPresented = true
    }

    private func handleMenuRequest() {
        isMenuPresented = true
    }
}
