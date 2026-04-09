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
///
/// `@unchecked Sendable` is safe here because every stored property is either:
/// - immutable (`let`) — `configuration`, `friendSnapshotService`, `isDebugBuild`,
///   `allowDebugScoreSubmission`, `isAuthenticatedProvider`, `authenticateHandlerSetter`,
///   `pendingScoreStore`; or
/// - protected by `leaderboardCacheLock` (`leaderboardCache`); or
/// - a `weak var` (`authenticationPresenter`) that is set exactly once at the composition
///   root before any concurrent access, always on the main actor.
/// No mutable state is shared across isolation boundaries after initialization.
public final class GameCenterService: LeaderboardService, @unchecked Sendable {
    private let configuration: LeaderboardConfiguration
    private let friendSnapshotService: GameCenterFriendSnapshotServicing
    private weak var authenticationPresenter: AuthenticationPresenter?
    private let authenticateHandlerSetter: AuthenticateHandlerSetter?
    private let isDebugBuild: Bool
    private let allowDebugScoreSubmission: Bool
    private let isAuthenticatedProvider: () -> Bool
    private let pendingScoreStore: (any PendingLeaderboardScoreStore)?

    private let leaderboardCacheLock = NSLock()
    private var leaderboardCache = [String: GKLeaderboard]()

    static func normalizedFriendSnapshot(
        remoteBestScore: Int?,
        entries: [FriendLeaderboardEntry]
    ) -> FriendLeaderboardSnapshot? {
        FriendLeaderboardSnapshot.normalized(remoteBestScore: remoteBestScore, friendEntries: entries)
    }

    public init(
        configuration: LeaderboardConfiguration,
        friendSnapshotService: GameCenterFriendSnapshotServicing,
        authenticationPresenter: AuthenticationPresenter? = nil,
        authenticateHandlerSetter: AuthenticateHandlerSetter? = nil,
        isDebugBuild: Bool,
        allowDebugScoreSubmission: Bool,
        isAuthenticatedProvider: @escaping () -> Bool = { GKLocalPlayer.local.isAuthenticated },
        pendingScoreStore: (any PendingLeaderboardScoreStore)? = nil
    ) {
        self.configuration = configuration
        self.friendSnapshotService = friendSnapshotService
        self.authenticationPresenter = authenticationPresenter
        self.authenticateHandlerSetter = authenticateHandlerSetter
        self.isDebugBuild = isDebugBuild
        self.allowDebugScoreSubmission = allowDebugScoreSubmission
        self.isAuthenticatedProvider = isAuthenticatedProvider
        self.pendingScoreStore = pendingScoreStore
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
            let improved = pendingScoreStore?.updatePendingBestScoreIfHigher(score, for: difficulty) ?? false
            AppLog.info(
                AppLog.game + AppLog.leaderboard,
                "🏆 Skipped score submit \(score) – player not authenticated; queued as pending (improved: \(improved), leaderboardID: \(leaderboardID), speed: \(difficulty.rawValue))"
            )
            return
        }

        submitScoreToGameCenter(score, leaderboardID: leaderboardID, difficulty: difficulty)
    }

    /// Submits any scores that were queued while the player was not authenticated.
    /// Call this after a Game Center authentication state change and on app-lifecycle transitions.
    public func flushPendingScoresIfPossible() {
        guard isScoreSubmissionEnabled, isAuthenticated() else { return }
        guard let pendingScoreStore else { return }

        let pending = pendingScoreStore.pendingDifficulties()
        guard pending.isEmpty == false else { return }

        for difficulty in pending {
            guard let score = pendingScoreStore.bestPendingScore(for: difficulty) else { continue }
            // Clear before submitting so a concurrent flush cannot double-submit.
            pendingScoreStore.clearPendingBestScore(for: difficulty)
            let leaderboardID = configuration.leaderboardID(for: difficulty)
            AppLog.info(
                AppLog.game + AppLog.leaderboard,
                "🏆 Flushing pending score \(score) to leaderboard \(leaderboardID) (speed: \(difficulty.rawValue))"
            )
            submitScoreToGameCenter(score, leaderboardID: leaderboardID, difficulty: difficulty)
        }
    }

    public func isAuthenticated() -> Bool {
        isAuthenticatedProvider()
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

    public func fetchFriendLeaderboardSnapshot(for difficulty: GameDifficulty) async -> FriendLeaderboardSnapshot? {
        let leaderboardID = configuration.leaderboardID(for: difficulty)

        guard isAuthenticated() else {
            AppLog.info(
                AppLog.game + AppLog.leaderboard,
                "🏆 Skipped friend leaderboard snapshot – player not authenticated (leaderboardID: \(leaderboardID), speed: \(difficulty.rawValue))"
            )
            return nil
        }

        guard let leaderboard = await loadLeaderboard(id: leaderboardID) else {
            return nil
        }

        let remoteBestScore = await loadLocalPlayerBestScore(from: leaderboard)
        guard let snapshot = await friendSnapshotService.fetchFriendSnapshot(
            from: leaderboard,
            remoteBestScore: remoteBestScore
        ) else {
            AppLog.info(
                AppLog.game + AppLog.leaderboard,
                "🏆 Friend leaderboard snapshot unavailable – no valid friend entries (leaderboardID: \(leaderboardID), speed: \(difficulty.rawValue))"
            )
            return nil
        }

        AppLog.info(
            AppLog.game + AppLog.leaderboard,
            "🏆 Loaded friend snapshot with \(snapshot.friendEntries.count) entries (remote best: \(snapshot.remoteBestScore.map(String.init) ?? "nil"), speed: \(difficulty.rawValue))"
        )
        return snapshot
    }

    // MARK: - Private submission

    private func submitScoreToGameCenter(_ score: Int, leaderboardID: String, difficulty: GameDifficulty) {
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

    // MARK: - Private leaderboard loading

    /// Returns a cached `GKLeaderboard` for `id` when available, otherwise fetches and caches it.
    private func loadLeaderboard(id: String) async -> GKLeaderboard? {
        let cached = leaderboardCacheLock.withLock { leaderboardCache[id] }
        if let cached {
            return cached
        }

        return await withCheckedContinuation { continuation in
            GKLeaderboard.loadLeaderboards(IDs: [id]) { [weak self] leaderboards, error in
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

                self?.leaderboardCacheLock.withLock {
                    self?.leaderboardCache[id] = leaderboard
                }
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

        // All three verification attempts failed — treat the submission as unconfirmed and
        // re-queue as pending so the next auth-change or lifecycle trigger retries it.
        let improved = pendingScoreStore?.updatePendingBestScoreIfHigher(submittedScore, for: difficulty) ?? false
        AppLog.info(
            AppLog.game + AppLog.leaderboard,
            "🏆 Could not verify remote best after submit on \(leaderboardID) after 3 attempts – re-queued as pending (improved: \(improved))"
        )
    }
}

