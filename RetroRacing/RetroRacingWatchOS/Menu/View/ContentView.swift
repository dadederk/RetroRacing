import SwiftUI
import RetroRacingShared

struct ContentView: View {
    let themeManager: ThemeManager
    let fontPreferenceStore: FontPreferenceStore
    let highestScoreStore: HighestScoreStore
    @State private var showGame = false
    @State private var gameID = 0
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(GameLocalizedStrings.string("gameName"))
                    .font(fontPreferenceStore.font(size: 14))
                Button {
                    gameID += 1
                    showGame = true
                } label: {
                    Text(GameLocalizedStrings.string("play"))
                        .font(fontPreferenceStore.font(size: 12))
                }
                .buttonStyle(.glassProminent)
            }
            .navigationDestination(isPresented: $showGame) {
                WatchGameView(theme: themeManager.currentTheme, fontPreferenceStore: fontPreferenceStore, highestScoreStore: highestScoreStore)
                    .id(gameID)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .buttonStyle(.glass)
                    .accessibilityLabel(GameLocalizedStrings.string("settings"))
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(themeManager: themeManager, fontPreferenceStore: fontPreferenceStore, supportsHapticFeedback: true)
            }
        }
    }
}

#Preview {
    ContentView(
        themeManager: ThemeManager(
            initialThemes: [LCDTheme(), GameBoyTheme()],
            defaultThemeID: "gameboy",
            userDefaults: InfrastructureDefaults.userDefaults
        ),
        fontPreferenceStore: FontPreferenceStore(
            userDefaults: InfrastructureDefaults.userDefaults,
            customFontAvailable: true
        ),
        highestScoreStore: UserDefaultsHighestScoreStore(userDefaults: InfrastructureDefaults.userDefaults)
    )
}
