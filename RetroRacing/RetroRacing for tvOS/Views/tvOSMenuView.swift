import SwiftUI
import RetroRacingShared

struct tvOSMenuView: View {
    let leaderboardService: LeaderboardService
    let gameCenterService: GameCenterService
    let ratingService: RatingService
    let leaderboardConfiguration: LeaderboardConfiguration

    @State private var showGame = false
    @State private var showLeaderboard = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 40) {
                Text("gameName")
                    .font(.custom("PressStart2P-Regular", size: 42))
                    .padding(.bottom, 60)

                Button {
                    showGame = true
                } label: {
                    Text("play")
                        .font(.custom("PressStart2P-Regular", size: 24))
                }
                .buttonStyle(.card)

                Button {
                    if gameCenterService.isAuthenticated() {
                        showLeaderboard = true
                    }
                } label: {
                    Text("leaderboard")
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
        }
    }
}
