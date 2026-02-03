//
//  RetroRacingWatchOSApp.swift
//  RetroRacingWatchOS
//

import SwiftUI
import RetroRacingShared

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
    private let fontPreferenceStore = FontPreferenceStore(
        userDefaults: InfrastructureDefaults.userDefaults,
        customFontAvailable: true
    )

    var body: some Scene {
        WindowGroup {
            ContentView(themeManager: themeManager, fontPreferenceStore: fontPreferenceStore)
        }
    }
}
