import Foundation
import GameKit

public final class GameCenterService: LeaderboardService {
    private let configuration: LeaderboardConfiguration
    private weak var authenticationPresenter: AuthenticationPresenter?

    public init(configuration: LeaderboardConfiguration, authenticationPresenter: AuthenticationPresenter? = nil) {
        self.configuration = configuration
        self.authenticationPresenter = authenticationPresenter
    }

    /// Call with the object that can present the authentication view controller when Game Center requests it.
    /// On watchOS, authentication is handled by the system; this method does not set a handler.
    public func authenticate(presenter: AuthenticationPresenter) {
        authenticationPresenter = presenter
        #if !os(watchOS)
        GKLocalPlayer.local.authenticateHandler = { [weak self] viewController, _ in
            guard let viewController = viewController else { return }
            self?.authenticationPresenter?.presentAuthenticationUI(viewController)
        }
        #endif
    }

    public func submitScore(_ score: Int) {
        guard isAuthenticated() else { return }

        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [configuration.leaderboardID]
        ) { error in
            if let error = error {
                print("Failed to submit score: \(error.localizedDescription)")
            }
        }
    }

    public func isAuthenticated() -> Bool {
        GKLocalPlayer.local.isAuthenticated
    }
}
