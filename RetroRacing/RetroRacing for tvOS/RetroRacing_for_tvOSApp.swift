import SwiftUI
import RetroRacingShared

@main
struct RetroRacing_for_tvOSApp: App {
    private let leaderboardConfiguration = tvOSLeaderboardConfiguration()
    private let gameCenterService: GameCenterService
    private let ratingService: RatingService

    init() {
        gameCenterService = GameCenterService(
            configuration: leaderboardConfiguration,
            authenticationPresenter: nil
        )
        ratingService = StoreReviewService(ratingProvider: tvOSRatingServiceProvider())
    }

    var body: some Scene {
        WindowGroup {
            tvOSMenuView(
                leaderboardService: gameCenterService,
                gameCenterService: gameCenterService,
                ratingService: ratingService,
                leaderboardConfiguration: leaderboardConfiguration
            )
        }
    }
}
