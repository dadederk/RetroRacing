//
//  FriendLeaderboardModels.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/04/2026.
//

import Foundation

/// Snapshot of local-player baseline and friend leaderboard entries for a selected speed.
public struct FriendLeaderboardSnapshot: Sendable, Equatable {
    public let remoteBestScore: Int?
    public var friendEntries: [FriendLeaderboardEntry]

    public init(remoteBestScore: Int?, friendEntries: [FriendLeaderboardEntry]) {
        self.remoteBestScore = remoteBestScore
        self.friendEntries = friendEntries
    }

    /// Returns a sanitized snapshot sorted by ascending score and deduplicated by player id.
    /// Keeps the highest score when duplicate player ids are present.
    public static func normalized(
        remoteBestScore: Int?,
        friendEntries: [FriendLeaderboardEntry]
    ) -> FriendLeaderboardSnapshot? {
        var bestByPlayerID = [String: FriendLeaderboardEntry]()

        for entry in friendEntries where entry.playerID.isEmpty == false && entry.score > 0 {
            if let existing = bestByPlayerID[entry.playerID] {
                if entry.score > existing.score {
                    bestByPlayerID[entry.playerID] = entry
                }
            } else {
                bestByPlayerID[entry.playerID] = entry
            }
        }

        let sortedEntries = bestByPlayerID.values.sorted {
            if $0.score == $1.score {
                return $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
            }
            return $0.score < $1.score
        }

        guard sortedEntries.isEmpty == false else { return nil }
        return FriendLeaderboardSnapshot(remoteBestScore: remoteBestScore, friendEntries: sortedEntries)
    }
}

/// Friend leaderboard row used by gameplay social milestones and game-over recap.
public struct FriendLeaderboardEntry: Sendable, Equatable, Identifiable {
    public let playerID: String
    public let displayName: String
    public let score: Int
    public let avatarPNGData: Data?

    public var id: String { playerID }

    public init(
        playerID: String,
        displayName: String,
        score: Int,
        avatarPNGData: Data? = nil
    ) {
        self.playerID = playerID
        self.displayName = displayName
        self.score = score
        self.avatarPNGData = avatarPNGData
    }
}

/// Summary row for the "next friend ahead" game-over section.
public struct GameOverFriendAheadSummary: Sendable, Equatable {
    public let playerID: String
    public let displayName: String
    public let score: Int
    public let avatarPNGData: Data?

    public init(
        playerID: String,
        displayName: String,
        score: Int,
        avatarPNGData: Data?
    ) {
        self.playerID = playerID
        self.displayName = displayName
        self.score = score
        self.avatarPNGData = avatarPNGData
    }
}

/// Summary row for "friends overtaken this run" game-over recap.
public struct GameOverOvertakenFriendSummary: Sendable, Equatable, Identifiable {
    public let playerID: String
    public let displayName: String
    public let score: Int
    public let avatarPNGData: Data?

    public var id: String { playerID }

    public init(
        playerID: String,
        displayName: String,
        score: Int,
        avatarPNGData: Data?
    ) {
        self.playerID = playerID
        self.displayName = displayName
        self.score = score
        self.avatarPNGData = avatarPNGData
    }
}

/// Single in-race milestone marker for a friend score the player is approaching.
public struct UpcomingFriendMilestone: Sendable, Equatable {
    public let playerID: String
    public let displayName: String
    public let targetScore: Int
    public let avatarPNGData: Data?

    public init(
        playerID: String,
        displayName: String,
        targetScore: Int,
        avatarPNGData: Data?
    ) {
        self.playerID = playerID
        self.displayName = displayName
        self.targetScore = targetScore
        self.avatarPNGData = avatarPNGData
    }
}
