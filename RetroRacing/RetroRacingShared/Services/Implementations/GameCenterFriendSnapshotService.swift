//
//  GameCenterFriendSnapshotService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 05/04/2026.
//

import Foundation
import GameKit

public final class GameCenterFriendSnapshotService: GameCenterFriendSnapshotServicing {
    private enum Configuration {
        static let pageSize = 100
        static let maxPages = 5
        static let avatarHydrationCount = 24
    }

    let avatarCache: any GameCenterAvatarCaching

    public init(avatarCache: any GameCenterAvatarCaching) {
        self.avatarCache = avatarCache
    }

    public func fetchFriendSnapshot(
        from leaderboard: GKLeaderboard,
        remoteBestScore: Int?
    ) async -> FriendLeaderboardSnapshot? {
        let rawFriendEntries = await loadRawFriendEntries(from: leaderboard)
        return await buildFriendSnapshot(remoteBestScore: remoteBestScore, rawFriendEntries: rawFriendEntries)
    }

    private func loadRawFriendEntries(from leaderboard: GKLeaderboard) async -> [GameCenterRawFriendEntry] {
        var allEntries = [GameCenterRawFriendEntry]()
        var location = 1

        for _ in 0..<Configuration.maxPages {
            let pageRange = NSRange(location: location, length: Configuration.pageSize)
            let pageEntries = await loadRawFriendEntriesPage(from: leaderboard, range: pageRange)
            guard pageEntries.isEmpty == false else { break }
            allEntries.append(contentsOf: pageEntries)

            if pageEntries.count < Configuration.pageSize {
                break
            }
            location += pageEntries.count
        }

        return allEntries
    }

    private func buildFriendSnapshot(
        remoteBestScore: Int?,
        rawFriendEntries: [GameCenterRawFriendEntry]
    ) async -> FriendLeaderboardSnapshot? {
        var playerByID = [String: GKPlayer]()
        var entries = [FriendLeaderboardEntry]()

        for rawEntry in rawFriendEntries {
            let playerID = Self.playerIdentifier(for: rawEntry.player)
            playerByID[playerID] = rawEntry.player
            let cachedAvatar = await avatarCache.data(for: playerID)
            entries.append(
                FriendLeaderboardEntry(
                    playerID: playerID,
                    displayName: rawEntry.player.displayName,
                    score: rawEntry.score,
                    avatarPNGData: cachedAvatar
                )
            )
        }

        guard var snapshot = GameCenterService.normalizedFriendSnapshot(
            remoteBestScore: remoteBestScore,
            entries: entries
        ) else {
            return nil
        }

        let candidateIDs = snapshot.friendEntries
            .prefix(Configuration.avatarHydrationCount)
            .map(\.playerID)

        for candidateID in candidateIDs {
            guard let player = playerByID[candidateID] else { continue }
            guard let avatarData = await loadAvatarData(for: player) else { continue }
            if let index = snapshot.friendEntries.firstIndex(where: { $0.playerID == candidateID }) {
                let current = snapshot.friendEntries[index]
                snapshot.friendEntries[index] = FriendLeaderboardEntry(
                    playerID: current.playerID,
                    displayName: current.displayName,
                    score: current.score,
                    avatarPNGData: avatarData
                )
            }
        }

        return snapshot
    }

    private func loadRawFriendEntriesPage(from leaderboard: GKLeaderboard, range: NSRange) async -> [GameCenterRawFriendEntry] {
        await withCheckedContinuation { continuation in
            leaderboard.loadEntries(
                for: .friendsOnly,
                timeScope: .allTime,
                range: range
            ) { _, entries, _, error in
                if let error {
                    let nsError = error as NSError
                    AppLog.error(
                        AppLog.game + AppLog.leaderboard,
                        "🏆 Failed loading friend entries: \(error.localizedDescription) (domain: \(nsError.domain), code: \(nsError.code), userInfo: \(nsError.userInfo))"
                    )
                    continuation.resume(returning: [])
                    return
                }

                let mapped = (entries ?? []).compactMap { entry -> GameCenterRawFriendEntry? in
                    let player = entry.player
                    let playerID = Self.playerIdentifier(for: player)
                    guard playerID.isEmpty == false else { return nil }
                    let score = Int(entry.score)
                    guard score > 0 else { return nil }
                    return GameCenterRawFriendEntry(player: player, score: score)
                }
                continuation.resume(returning: mapped)
            }
        }
    }

    private func loadAvatarData(for player: GKPlayer) async -> Data? {
#if os(watchOS)
        // watchOS v1 scope: no social avatar hydration.
        return nil
#else
        let playerID = Self.playerIdentifier(for: player)
        if let cached = await avatarCache.data(for: playerID) {
            return cached
        }

        guard #available(iOS 14.0, tvOS 14.0, macOS 11.0, *) else {
            return nil
        }

        return await loadAvatarDataIfAvailable(for: player, playerID: playerID)
#endif
    }

    private static func playerIdentifier(for player: GKPlayer) -> String {
#if os(watchOS)
        // watchOS does not expose gamePlayerID/teamPlayerID.
        return player.displayName
#else
        guard #available(iOS 12.4, tvOS 12.4, macOS 10.14.6, *) else {
            return player.displayName
        }
        return player.gamePlayerID
#endif
    }

}
