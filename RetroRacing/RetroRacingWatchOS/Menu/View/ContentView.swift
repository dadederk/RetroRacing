import SwiftUI
import RetroRacingShared

struct ContentView: View {
    let themeManager: ThemeManager
    let fontPreferenceStore: FontPreferenceStore
    let highestScoreStore: HighestScoreStore
    let leaderboardService: LeaderboardService
    @State private var showGame = false
    @State private var gameID = 0
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Text(GameLocalizedStrings.string("gameName"))
                    .font(fontPreferenceStore.font(textStyle: .headline))
                Button {
                    gameID += 1
                    showGame = true
                } label: {
                    Text(GameLocalizedStrings.string("play"))
                        .font(fontPreferenceStore.font(textStyle: .body))
                }
                .buttonStyle(.glassProminent)
            }
            .fontPreferenceStore(fontPreferenceStore)
            .navigationDestination(isPresented: $showGame) {
                WatchGameView(
                    theme: themeManager.currentTheme,
                    fontPreferenceStore: fontPreferenceStore,
                    highestScoreStore: highestScoreStore,
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
                let settingsHapticController = WatchHapticFeedbackController(
                    userDefaults: InfrastructureDefaults.userDefaults
                )
                let previewDependencies = settingsPreviewDependencyFactory.make(
                    hapticController: settingsHapticController
                )
                SettingsView(
                    themeManager: themeManager,
                    fontPreferenceStore: fontPreferenceStore,
                    supportsHapticFeedback: true,
                    hapticController: settingsHapticController,
                    audioCueTutorialPreviewPlayer: previewDependencies.audioCueTutorialPreviewPlayer,
                    speedWarningFeedbackPreviewPlayer: previewDependencies.speedWarningFeedbackPreviewPlayer,
                    isGameCenterAuthenticated: leaderboardService.isAuthenticated()
                )
            }
        }
    }

    private var settingsPreviewDependencyFactory: SettingsPreviewDependencyFactory {
        SettingsPreviewDependencyFactory(
            laneCuePlayerFactory: { PlatformFactories.makeLaneCuePlayer() },
            announcementPoster: AccessibilityAnnouncementPoster(),
            announcementTextProvider: {
                GameLocalizedStrings.string("speed_increase_announcement")
            },
            volumeProvider: {
                SoundEffectsVolumePreference.currentSelection(from: InfrastructureDefaults.userDefaults)
            }
        )
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
        leaderboardService: PreviewLeaderboardService()
    )
}

/// Preview-only leaderboard service (no-op).
private struct PreviewLeaderboardService: LeaderboardService {
    func submitScore(_ score: Int, difficulty: GameDifficulty) {}
    func isAuthenticated() -> Bool { true }
    func fetchLocalPlayerBestScore(for difficulty: GameDifficulty) async -> Int? { nil }
}
