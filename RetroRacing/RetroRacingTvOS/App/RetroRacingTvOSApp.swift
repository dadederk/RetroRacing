import SwiftUI
import RetroRacingShared
import GameKit

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
    private let playLimitService: PlayLimitService
    private let storeKitService = StoreKitService()
    @State private var isMenuPresented = true
    @State private var sessionID = UUID()

    init() {
        AppBootstrap.configureAudioSession()
        AppBootstrap.configureGameCenterAccessPoint()
        let customFontAvailable = AppBootstrap.registerCustomFont()
        let userDefaults = InfrastructureDefaults.userDefaults
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
            leaderboardID: leaderboardConfiguration.leaderboardID,
            authenticateHandlerSetter: { presenter in
                GKLocalPlayer.local.authenticateHandler = { viewController, _ in
                    guard let viewController = viewController else { return }
                    presenter.presentAuthenticationUI(viewController)
                }
            }
        )
        gameCenterService = GameCenterService(
            configuration: leaderboardConfiguration,
            authenticationPresenter: authenticationPresenter,
            authenticateHandlerSetter: leaderboardConfig.authenticateHandlerSetter
        )
        ratingService = StoreReviewService(userDefaults: userDefaults, ratingProvider: RatingServiceProviderTvOS())
        highestScoreStore = UserDefaultsHighestScoreStore(userDefaults: userDefaults)
        playLimitService = UserDefaultsPlayLimitService(userDefaults: userDefaults)

        BuildConfiguration.initializeTestFlightCheck()
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
                    fontPreferenceStore: fontPreferenceStore,
                    highestScoreStore: highestScoreStore,
                    playLimitService: playLimitService,
                    style: .tvOS,
                    inputAdapterFactory: RemoteInputAdapterFactory(),
                    showMenuButton: true,
                    onFinishRequest: handleFinish,
                    onMenuRequest: handleMenuRequest,
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
            .task {
                await storeKitService.loadProducts()
            }
        }
    }

    private func handlePlayRequest() {
        AppLog.info(AppLog.game, "Play requested - starting new session and dismissing menu")
        sessionID = UUID()
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
