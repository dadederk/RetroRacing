import SwiftUI
import RetroRacingShared

struct tvOSMenuView: View {
    let leaderboardService: LeaderboardService
    let gameCenterService: GameCenterService
    let ratingService: RatingService
    let leaderboardConfiguration: LeaderboardConfiguration

    @State private var showGame = false
    @State private var showLeaderboard = false
    @State private var showSettings = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Text(GameLocalizedStrings.string("gameName"))
                    .font(.custom("PressStart2P-Regular", size: 42))
                    .padding(.bottom, 60)

                Button {
                    showGame = true
                } label: {
                    Text(GameLocalizedStrings.string("play"))
                        .font(.custom("PressStart2P-Regular", size: 24))
                }
                .buttonStyle(.card)

                Button {
                    if gameCenterService.isAuthenticated() {
                        showLeaderboard = true
                    }
                } label: {
                    Text(GameLocalizedStrings.string("leaderboard"))
                        .font(.custom("PressStart2P-Regular", size: 24))
                }
                .buttonStyle(.card)
            }
            .navigationDestination(isPresented: $showGame) {
                tvOSGameView(
                    leaderboardService: leaderboardService,
                    ratingService: ratingService
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
                tvOSSettingsView()
            }
        }
    }
}
