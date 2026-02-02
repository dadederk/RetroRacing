//
//  RetroRacingWatchOSApp.swift
//  RetroRacingWatchOS
//

import SwiftUI
import RetroRacingShared

@main
struct RetroRacingWatchOSApp: App {
    private let themeManager = ThemeManager(
        initialThemes: [LCDTheme(), GameBoyTheme()],
        defaultThemeID: "gameboy"
    )
    private let fontPreferenceStore = FontPreferenceStore()

    var body: some Scene {
        WindowGroup {
            ContentView(themeManager: themeManager, fontPreferenceStore: fontPreferenceStore)
        }
    }
}
