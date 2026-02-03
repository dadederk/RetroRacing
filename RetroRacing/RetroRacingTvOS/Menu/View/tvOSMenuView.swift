import SwiftUI
import RetroRacingShared

struct tvOSMenuView: View {
    let leaderboardService: LeaderboardService
    let gameCenterService: GameCenterService
    let ratingService: RatingService
    let leaderboardConfiguration: LeaderboardConfiguration
    let themeManager: ThemeManager
    let fontPreferenceStore: FontPreferenceStore
    let hapticController: HapticFeedbackController
    let highestScoreStore: HighestScoreStore

    @State private var showGame = false
    @State private var showLeaderboard = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Text(GameLocalizedStrings.string("gameName"))
                    .font(fontPreferenceStore.font(size: 42))
                    .padding(.bottom, 60)

                Button {
                    showGame = true
                } label: {
                    Text(GameLocalizedStrings.string("play"))
                        .font(fontPreferenceStore.font(size: 24))
                }
                .buttonStyle(.card)

                Button {
                    if gameCenterService.isAuthenticated() {
                        showLeaderboard = true
                    }
                } label: {
                    Text(GameLocalizedStrings.string("leaderboard"))
                        .font(fontPreferenceStore.font(size: 24))
                }
                .buttonStyle(.card)
            }
            .navigationDestination(isPresented: $showGame) {
                tvOSGameView(
                    leaderboardService: leaderboardService,
                    ratingService: ratingService,
                    theme: themeManager.currentTheme,
                    hapticController: hapticController,
                    fontPreferenceStore: fontPreferenceStore,
                    highestScoreStore: highestScoreStore
                )
            }
            .fullScreenCover(isPresented: $showLeaderboard) {
                tvOSLeaderboardView(leaderboardID: leaderboardConfiguration.leaderboardID) {
                    showLeaderboard = false
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showSettings = true
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel(GameLocalizedStrings.string("settings"))
                }
            }
            .sheet(isPresented: $showSettings) {
                tvOSSettingsView(themeManager: themeManager, fontPreferenceStore: fontPreferenceStore, supportsHapticFeedback: false)
            }
        }
    }
}
