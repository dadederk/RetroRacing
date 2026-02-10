import SwiftUI
import RetroRacingShared

struct ContentView: View {
    let themeManager: ThemeManager
    let fontPreferenceStore: FontPreferenceStore
    let highestScoreStore: HighestScoreStore
    let crownConfiguration: LegacyCrownInputProcessor.Configuration
    let leaderboardService: LeaderboardService
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
            .fontPreferenceStore(fontPreferenceStore)
            .navigationDestination(isPresented: $showGame) {
                WatchGameView(
                    theme: themeManager.currentTheme,
                    fontPreferenceStore: fontPreferenceStore,
                    highestScoreStore: highestScoreStore,
                    crownConfiguration: crownConfiguration,
                    leaderboardService: leaderboardService
                )
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
                SettingsView(
                    themeManager: themeManager,
                    fontPreferenceStore: fontPreferenceStore,
                    supportsHapticFeedback: true,
                    isGameCenterAuthenticated: leaderboardService.isAuthenticated()
                )
            }
        }
    }
}

#Preview {
    ContentView(
        themeManager: ThemeManager(
            initialThemes: [LCDTheme(), PocketTheme()],
            defaultThemeID: "pocket",
            userDefaults: InfrastructureDefaults.userDefaults
        ),
        fontPreferenceStore: FontPreferenceStore(
            userDefaults: InfrastructureDefaults.userDefaults,
            customFontAvailable: true
        ),
        highestScoreStore: UserDefaultsHighestScoreStore(userDefaults: InfrastructureDefaults.userDefaults),
        crownConfiguration: .watchLegacy,
        leaderboardService: PreviewLeaderboardService()
    )
}

/// Preview-only leaderboard service (no-op).
private struct PreviewLeaderboardService: LeaderboardService {
    func submitScore(_ score: Int) {}
    func isAuthenticated() -> Bool { true }
}

private final class PreviewRatingServiceForSettings: RatingService {
    func requestRating() {}
    func checkAndRequestRating(score: Int) {}
}
