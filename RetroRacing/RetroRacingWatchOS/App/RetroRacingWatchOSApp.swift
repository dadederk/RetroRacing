//
//  RetroRacingWatchOSApp.swift
//  RetroRacingWatchOS
//

import SwiftUI
import RetroRacingShared
import CoreText
import GameKit
#if canImport(WatchKit)
import WatchKit
#endif

/// Game Center leaderboard configuration for watchOS sandbox.
private struct LeaderboardConfigurationWatchOS: LeaderboardConfiguration {
    let leaderboardID = "bestwatchos001test"
}

@main
struct RetroRacingWatchOSApp: App {
    private let themeManager: ThemeManager = {
        let config = ThemePlatformConfig(
            defaultThemeID: "gameboy",
            availableThemes: [LCDTheme(), GameBoyTheme()]
        )
        return ThemeManager(
            initialThemes: config.availableThemes,
            defaultThemeID: config.defaultThemeID,
            userDefaults: InfrastructureDefaults.userDefaults
        )
    }()
    private let crownConfiguration = LegacyCrownInputProcessor.Configuration.watchLegacy
    private let leaderboardService: GameCenterService
    private let fontPreferenceStore: FontPreferenceStore
    private let highestScoreStore = UserDefaultsHighestScoreStore(userDefaults: InfrastructureDefaults.userDefaults)
    private let playLimitService = UserDefaultsPlayLimitService(userDefaults: InfrastructureDefaults.userDefaults)

    var body: some Scene {
        WindowGroup {
            ContentView(
                themeManager: themeManager,
                fontPreferenceStore: fontPreferenceStore,
                highestScoreStore: highestScoreStore,
                crownConfiguration: crownConfiguration,
                leaderboardService: leaderboardService
            )
            .onAppear {
                Self.setupGameCenterAuthentication()
            }
        }
    }

    init() {
        let customFontAvailable = FontRegistrar.registerPressStart2P(additionalBundles: [Bundle.main])
        fontPreferenceStore = FontPreferenceStore(
            userDefaults: InfrastructureDefaults.userDefaults,
            customFontAvailable: customFontAvailable
        )
        
        // Initialize Game Center service for watchOS
        let configuration = LeaderboardConfigurationWatchOS()
        leaderboardService = GameCenterService(
            configuration: configuration,
            authenticationPresenter: nil,
            authenticateHandlerSetter: nil
        )
    }
    
    private static func setupGameCenterAuthentication() {
        AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS setting up Game Center authentication")
        GKLocalPlayer.local.authenticateHandler = { error in
            if let error = error {
                AppLog.error(AppLog.game + AppLog.leaderboard, "🏆 watchOS Game Center authentication error: \(error.localizedDescription)")
                return
            }
            // No error = auth completed (success or silent failure)
            if GKLocalPlayer.local.isAuthenticated {
                AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS Game Center authenticated successfully - player: \(GKLocalPlayer.local.displayName)")
            } else {
                AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS Game Center authentication handler called, but player not authenticated")
            }
        }
    }
}

/// No-op authentication presenter for watchOS (no UI to present).
private final class NoOpAuthenticationPresenter: AuthenticationPresenter {
    func presentAuthenticationUI(_ viewController: Any) {
        AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 watchOS NoOpAuthenticationPresenter.presentAuthenticationUI called (no-op)")
    }
}
