//
//  GameCenterService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import GameKit

/// Called when authentication UI should be registered with Game Center. Pass from the app layer; pass `nil` on watchOS (system handles auth).
public typealias AuthenticateHandlerSetter = (AuthenticationPresenter) -> Void

/// Game Center-backed leaderboard service handling authentication wiring and score submission.
public final class GameCenterService: LeaderboardService {
    private let configuration: LeaderboardConfiguration
    private weak var authenticationPresenter: AuthenticationPresenter?
    private let authenticateHandlerSetter: AuthenticateHandlerSetter?

    public init(
        configuration: LeaderboardConfiguration,
        authenticationPresenter: AuthenticationPresenter? = nil,
        authenticateHandlerSetter: AuthenticateHandlerSetter? = nil
    ) {
        self.configuration = configuration
        self.authenticationPresenter = authenticationPresenter
        self.authenticateHandlerSetter = authenticateHandlerSetter
    }

    /// Call with the object that can present the authentication view controller when Game Center requests it.
    /// When `authenticateHandlerSetter` was provided at init, it is invoked so the app can register the handler (e.g. set `GKLocalPlayer.local.authenticateHandler`). On watchOS, pass `nil` for the setter at init; the system handles authentication.
    public func authenticate(presenter: AuthenticationPresenter) {
        authenticationPresenter = presenter
        authenticateHandlerSetter?(presenter)
    }

    public func submitScore(_ score: Int) {
        guard isAuthenticated() else {
            AppLog.info(AppLog.game, "Skipped score submit \(score) because player not authenticated")
            return
        }

        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [configuration.leaderboardID]
        ) { error in
            if let error = error {
                AppLog.error(AppLog.game, "Failed to submit score \(score): \(error.localizedDescription)")
            }
        }
    }

    public func isAuthenticated() -> Bool {
        GKLocalPlayer.local.isAuthenticated
    }
}
