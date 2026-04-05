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
