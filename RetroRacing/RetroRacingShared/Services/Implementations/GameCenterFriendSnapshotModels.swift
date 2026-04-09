//
//  GameCenterFriendSnapshotModels.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 05/04/2026.
//

import Foundation
import GameKit

struct GameCenterRawFriendEntry {
    let player: GKPlayer
    let score: Int
}

/// Configuration for `GameCenterFriendSnapshotService` that separates platform-scoping
/// decisions from the service implementation. Set at the composition root; no `#if os()`
/// required inside the service itself.
public struct GameCenterFriendSnapshotConfiguration: Sendable {
    /// Whether friend leaderboard entries should be fetched. Set to `false` on platforms
    /// where friend hydration is out of scope (e.g. watchOS v1).
    public let friendLeaderboardEnabled: Bool

    /// Whether friend avatar images should be loaded and cached. Set to `false` on
    /// platforms that don't support `GKPlayer.loadPhoto` (e.g. watchOS).
    public let avatarHydrationEnabled: Bool

    /// Strategy for deriving a stable player identifier from a `GKPlayer`. On platforms
    /// where `gamePlayerID` is unavailable (e.g. watchOS), supply `\.displayName` instead.
    public let playerIdentifier: @Sendable (GKPlayer) -> String

    public init(
        friendLeaderboardEnabled: Bool,
        avatarHydrationEnabled: Bool,
        playerIdentifier: @escaping @Sendable (GKPlayer) -> String
    ) {
        self.friendLeaderboardEnabled = friendLeaderboardEnabled
        self.avatarHydrationEnabled = avatarHydrationEnabled
        self.playerIdentifier = playerIdentifier
    }
}

public extension GameCenterFriendSnapshotConfiguration {
    /// Full-featured configuration for platforms that support friend leaderboards and
    /// avatar loading (iOS, macOS, tvOS, visionOS).
    static var standard: GameCenterFriendSnapshotConfiguration {
        GameCenterFriendSnapshotConfiguration(
            friendLeaderboardEnabled: true,
            avatarHydrationEnabled: true,
            // gamePlayerID is a compiler-level unavailable symbol on watchOS (not just
            // a runtime availability gap), so a compile-time guard is required here.
            // Compose with .watchOS on watchOS — this factory is for other platforms.
            playerIdentifier: { player in
                #if os(watchOS)
                return player.displayName
                #else
                if #available(iOS 12.4, tvOS 12.4, macOS 10.14.6, *) {
                    return player.gamePlayerID
                }
                return player.displayName
                #endif
            }
        )
    }

    /// watchOS configuration: friend leaderboard and avatar hydration are out of scope
    /// for v1. `displayName` is used as the identifier because `gamePlayerID` is
    /// unavailable on watchOS.
    static var watchOS: GameCenterFriendSnapshotConfiguration {
        GameCenterFriendSnapshotConfiguration(
            friendLeaderboardEnabled: false,
            avatarHydrationEnabled: false,
            playerIdentifier: { player in player.displayName }
        )
    }
}

public protocol GameCenterFriendSnapshotServicing: Sendable {
    func fetchFriendSnapshot(
        from leaderboard: GKLeaderboard,
        remoteBestScore: Int?
    ) async -> FriendLeaderboardSnapshot?
}

public protocol GameCenterAvatarCaching: Sendable {
    func data(for playerID: String) async -> Data?
    func cache(_ data: Data, for playerID: String) async
}

public actor GameCenterAvatarCache: GameCenterAvatarCaching {
    private var byPlayerID = [String: Data]()

    public init() {}

    public func data(for playerID: String) -> Data? {
        byPlayerID[playerID]
    }

    public func cache(_ data: Data, for playerID: String) {
        byPlayerID[playerID] = data
    }
}
