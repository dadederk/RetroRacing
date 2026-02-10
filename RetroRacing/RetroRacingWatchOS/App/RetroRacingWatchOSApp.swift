//
//  RetroRacingWatchOSApp.swift
//  RetroRacingWatchOS
//

import SwiftUI
import RetroRacingShared
import CoreText

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
    private let leaderboardService: LeaderboardService = GameCenterService(
        configuration: LeaderboardConfigurationWatchOS(),
        authenticationPresenter: nil,
        authenticateHandlerSetter: nil
    )
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
        }
    }

    init() {
        let customFontAvailable = FontRegistrar.registerPressStart2P(additionalBundles: [Bundle.main])
        fontPreferenceStore = FontPreferenceStore(
            userDefaults: InfrastructureDefaults.userDefaults,
            customFontAvailable: customFontAvailable
        )
    }
}
