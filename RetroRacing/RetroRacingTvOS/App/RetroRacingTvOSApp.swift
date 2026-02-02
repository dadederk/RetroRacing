import SwiftUI
import RetroRacingShared
import GameKit

@main
struct RetroRacingTvOSApp: App {
    private let leaderboardConfiguration = LeaderboardConfigurationTvOS()
    private let gameCenterService: GameCenterService
    private let ratingService: RatingService
    private let themeManager: ThemeManager
    private let fontPreferenceStore: FontPreferenceStore
    private let hapticController: HapticFeedbackController

    init() {
        themeManager = ThemeManager(
            initialThemes: [LCDTheme(), GameBoyTheme()],
            defaultThemeID: "lcd",
            userDefaults: .standard
        )
        fontPreferenceStore = FontPreferenceStore(customFontAvailable: false)
        hapticController = NoOpHapticFeedbackController()
        gameCenterService = GameCenterService(
            configuration: leaderboardConfiguration,
            authenticationPresenter: nil,
            authenticateHandlerSetter: { presenter in
                GKLocalPlayer.local.authenticateHandler = { viewController, _ in
                    guard let viewController = viewController else { return }
                    presenter.presentAuthenticationUI(viewController)
                }
            }
        )
        ratingService = StoreReviewService(ratingProvider: RatingServiceProviderTvOS())
    }

    var body: some Scene {
        WindowGroup {
            tvOSMenuView(
                leaderboardService: gameCenterService,
                gameCenterService: gameCenterService,
                ratingService: ratingService,
                leaderboardConfiguration: leaderboardConfiguration,
                themeManager: themeManager,
                fontPreferenceStore: fontPreferenceStore,
                hapticController: hapticController
            )
        }
    }
}
