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
    private let isDebugBuild: Bool
    private let allowDebugScoreSubmission: Bool

    public init(
        configuration: LeaderboardConfiguration,
        authenticationPresenter: AuthenticationPresenter? = nil,
        authenticateHandlerSetter: AuthenticateHandlerSetter? = nil,
        isDebugBuild: Bool,
        allowDebugScoreSubmission: Bool
    ) {
        self.configuration = configuration
        self.authenticationPresenter = authenticationPresenter
        self.authenticateHandlerSetter = authenticateHandlerSetter
        self.isDebugBuild = isDebugBuild
        self.allowDebugScoreSubmission = allowDebugScoreSubmission
    }

    /// Call with the object that can present the authentication view controller when Game Center requests it.
    /// When `authenticateHandlerSetter` was provided at init, it is invoked so the app can register the handler (e.g. set `GKLocalPlayer.local.authenticateHandler`). On watchOS, pass `nil` for the setter at init; the system handles authentication.
    public func authenticate(presenter: AuthenticationPresenter) {
        authenticationPresenter = presenter
        authenticateHandlerSetter?(presenter)
    }

    public func submitScore(_ score: Int, difficulty: GameDifficulty) {
        let leaderboardID = configuration.leaderboardID(for: difficulty)

        guard isScoreSubmissionEnabled else {
            AppLog.info(
                AppLog.game + AppLog.leaderboard,
                "🏆 Skipped score submit \(score) – debug build (leaderboardID: \(leaderboardID), speed: \(difficulty.rawValue))"
            )
            return
        }

        guard isAuthenticated() else {
            AppLog.info(
                AppLog.game + AppLog.leaderboard,
                "🏆 Skipped score submit \(score) – player not authenticated (leaderboardID: \(leaderboardID), speed: \(difficulty.rawValue))"
            )
            return
        }

        AppLog.info(
            AppLog.game + AppLog.leaderboard,
            "🏆 Submitting score \(score) to leaderboard \(leaderboardID) (speed: \(difficulty.rawValue))"
        )

        GKLeaderboard.submitScore(
            score,
            context: 0,
            player: GKLocalPlayer.local,
            leaderboardIDs: [leaderboardID]
        ) { error in
            if let error = error {
                AppLog.error(AppLog.game + AppLog.leaderboard, "🏆 Failed to submit score \(score) to \(leaderboardID): \(error.localizedDescription)")
            } else {
                AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 Successfully submitted score \(score) to \(leaderboardID)")
                Task { [weak self] in
                    guard let self else { return }
                    await self.verifyRemoteBestAfterSubmit(
                        submittedScore: score,
                        difficulty: difficulty,
                        leaderboardID: leaderboardID
                    )
                }
            }
        }
    }

    public func isAuthenticated() -> Bool {
        GKLocalPlayer.local.isAuthenticated
    }

    var isScoreSubmissionEnabled: Bool {
        allowDebugScoreSubmission || !isDebugBuild
    }

    public func fetchLocalPlayerBestScore(for difficulty: GameDifficulty) async -> Int? {
        let leaderboardID = configuration.leaderboardID(for: difficulty)

        guard isAuthenticated() else {
            AppLog.info(
                AppLog.game + AppLog.leaderboard,
                "🏆 Skipped remote best sync – player not authenticated (leaderboardID: \(leaderboardID), speed: \(difficulty.rawValue))"
            )
            return nil
        }

        guard let leaderboard = await loadLeaderboard(id: leaderboardID) else {
            return nil
        }

        return await loadLocalPlayerBestScore(from: leaderboard)
    }

    private func loadLeaderboard(id: String) async -> GKLeaderboard? {
        await withCheckedContinuation { continuation in
            GKLeaderboard.loadLeaderboards(IDs: [id]) { leaderboards, error in
                if let error {
                    let nsError = error as NSError
                    AppLog.error(
                        AppLog.game + AppLog.leaderboard,
                        "🏆 Failed loading leaderboard \(id): \(error.localizedDescription) (domain: \(nsError.domain), code: \(nsError.code), userInfo: \(nsError.userInfo))"
                    )
                    continuation.resume(returning: nil)
                    return
                }

                guard let leaderboard = leaderboards?.first else {
                    AppLog.info(
                        AppLog.game + AppLog.leaderboard,
                        "🏆 No leaderboard returned for id \(id)"
                    )
                    continuation.resume(returning: nil)
                    return
                }

                let metadata = "releaseState=\(leaderboard.releaseState.rawValue), isHidden=\(leaderboard.isHidden), activityIdentifier=\(leaderboard.activityIdentifier)"
                AppLog.info(
                    AppLog.game + AppLog.leaderboard,
                    "🏆 Loaded leaderboard metadata for \(id): \(metadata)"
                )

                continuation.resume(returning: leaderboard)
            }
        }
    }

    private func loadLocalPlayerBestScore(from leaderboard: GKLeaderboard) async -> Int? {
        await withCheckedContinuation { continuation in
            leaderboard.loadEntries(
                for: .global,
                timeScope: .allTime,
                range: NSRange(location: 1, length: 1)
            ) { localPlayerEntry, _, _, error in
                if let error {
                    let nsError = error as NSError
                    AppLog.error(
                        AppLog.game + AppLog.leaderboard,
                        "🏆 Failed loading local player entry: \(error.localizedDescription) (domain: \(nsError.domain), code: \(nsError.code), userInfo: \(nsError.userInfo))"
                    )
                    continuation.resume(returning: nil)
                    return
                }

                guard let score = localPlayerEntry?.score else {
                    AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 Local player has no score entry yet")
                    continuation.resume(returning: nil)
                    return
                }

                AppLog.info(AppLog.game + AppLog.leaderboard, "🏆 Loaded remote best score \(score)")
                continuation.resume(returning: score)
            }
        }
    }

    private func verifyRemoteBestAfterSubmit(
        submittedScore: Int,
        difficulty: GameDifficulty,
        leaderboardID: String
    ) async {
        for attempt in 1...3 {
            if attempt > 1 {
                try? await Task.sleep(for: .seconds(2))
            }

            let verifiedBest = await fetchLocalPlayerBestScore(for: difficulty)
            if let verifiedBest {
                AppLog.info(
                    AppLog.game + AppLog.leaderboard,
                    "🏆 Verified remote best after submit on \(leaderboardID): \(verifiedBest) (submitted: \(submittedScore), attempt: \(attempt))"
                )
                return
            }
        }

        AppLog.info(
            AppLog.game + AppLog.leaderboard,
            "🏆 Could not verify remote best after submit on \(leaderboardID) after 3 attempts"
        )
    }
}
