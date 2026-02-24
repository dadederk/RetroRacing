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

/// App entry point assembling shared services and presenting the universal menu scene.
@main
struct RetroRacingApp: App {
    private let leaderboardConfiguration: LeaderboardConfiguration
    #if canImport(UIKit)
    private let authenticationPresenter = AuthenticationPresenterUniversal()
    #else
    private let authenticationPresenter = NoOpAuthenticationPresenter()
    #endif
    private let gameCenterService: GameCenterService
    private let ratingService: RatingService
    private let themeManager: ThemeManager
    private let fontPreferenceStore: FontPreferenceStore
    private let hapticController: HapticFeedbackController
    private let supportsHapticFeedback: Bool
    private let highestScoreStore: HighestScoreStore
    private let bestScoreSyncService: BestScoreSyncService
    private let playLimitService: PlayLimitService
    private let storeKitService: StoreKitService
    private let controlsDescriptionKey: String
    @State private var isMenuPresented = true
    /// Controls whether gameplay should be allowed to start for the current session.
    /// On initial launch and after Finish, this is false so that the SpriteKit
    /// scene is not created until the menu overlay is dismissed via Play.
    @State private var shouldStartGame = false
    @State private var sessionID = UUID()

    init() {
        AppBootstrap.configureAudioSession()
        AppBootstrap.configureGameCenterAccessPoint()
        let customFontAvailable = AppBootstrap.registerCustomFont()
        let userDefaults = InfrastructureDefaults.userDefaults
        let supportsHaptics = Self.deviceSupportsHapticFeedback()
        SettingsPreferenceMigration.runIfNeeded(
            userDefaults: userDefaults,
            supportsHaptics: supportsHaptics
        )
        storeKitService = StoreKitService(userDefaults: userDefaults)
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
            authenticationPresenter: authenticationPresenter,
            authenticateHandlerSetter: leaderboardPlatformConfig.authenticateHandlerSetter,
            isDebugBuild: BuildConfiguration.isDebug
        )
        #if canImport(UIKit)
        ratingService = StoreReviewService(userDefaults: userDefaults, ratingProvider: RatingServiceProviderUniversal())
        #else
        ratingService = StoreReviewService(userDefaults: userDefaults, ratingProvider: RatingServiceProviderMac())
        #endif
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
        let hapticsConfig = HapticsPlatformConfig(
            supportsHaptics: supportsHaptics,
            controllerProvider: { Self.makeHapticsController(userDefaults: userDefaults) }
        )
        hapticController = hapticsConfig.controllerProvider()
        supportsHapticFeedback = hapticsConfig.supportsHaptics
        highestScoreStore = UserDefaultsHighestScoreStore(userDefaults: userDefaults)
        bestScoreSyncService = BestScoreSyncService(
            leaderboardService: gameCenterService,
            highestScoreStore: highestScoreStore,
            difficultyProvider: {
                GameDifficulty.currentSelection(from: userDefaults)
            }
        )

        BuildConfiguration.initializeTestFlightCheck()
        playLimitService = UserDefaultsPlayLimitService(userDefaults: userDefaults)
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

    var body: some Scene {
        WindowGroup {
            NavigationStack {
                rootView
                    .environment(storeKitService)
                    .task {
                        await storeKitService.loadProducts()
                        await bestScoreSyncService.syncIfPossible()
                    }
                    .onReceive(NotificationCenter.default.publisher(for: .GKPlayerAuthenticationDidChangeNotificationName)) { _ in
                        Task {
                            await bestScoreSyncService.syncIfPossible()
                        }
                    }
            }
        }
    }

    /// Platform-aware root content that composes the shared game view and menu presentation.
    @ViewBuilder
    private var rootView: some View {
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
            .sheet(isPresented: $isMenuPresented, onDismiss: handleMenuDismissed) {
                menuView
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .ignoresSafeArea()
            }
            .animation(nil, value: isMenuPresented)
        #endif
    }

    /// Shared game view used across platforms.
    private var gameView: some View {
        GameView(
            leaderboardService: gameCenterService,
            ratingService: ratingService,
            theme: themeManager.currentTheme,
            hapticController: hapticController,
            fontPreferenceStore: fontPreferenceStore,
            highestScoreStore: highestScoreStore,
            playLimitService: playLimitService,
            style: .universal,
            inputAdapterFactory: TouchInputAdapterFactory(),
            controlsDescriptionKey: controlsDescriptionKey,
            shouldStartGame: shouldStartGame,
            showMenuButton: true,
            onFinishRequest: handleFinish,
            onMenuRequest: handleMenuRequest,
            isMenuOverlayPresented: $isMenuPresented
        )
        .id(sessionID)
        .navigationTitle("")
    }

    /// Shared menu view presented on top of the game.
    private var menuView: some View {
        MenuView(
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
            playLimitService: playLimitService,
            style: .universal,
            settingsStyle: .universal,
            gameViewStyle: .universal,
            controlsDescriptionKey: controlsDescriptionKey,
            showRateButton: true,
            inputAdapterFactory: TouchInputAdapterFactory(),
            onPlayRequest: handlePlayRequest
        )
        .interactiveDismissDisabled(true)
    }

    private func handlePlayRequest() {
        AppLog.info(AppLog.game, "Play requested - starting new session and dismissing menu")
        shouldStartGame = true
        sessionID = UUID()
        isMenuPresented = false
    }

    private func handleMenuDismissed() {
        AppLog.info(AppLog.game, "Menu dismissed")
    }

    private func handleFinish() {
        AppLog.info(AppLog.game, "Finish requested - showing menu")
        // Reset to a fresh pre-game state: new session and gated start.
        sessionID = UUID()
        shouldStartGame = false
        isMenuPresented = true
    }

    private func handleMenuRequest() {
        AppLog.info(AppLog.game, "Menu requested during gameplay")
        isMenuPresented = true
    }
}
