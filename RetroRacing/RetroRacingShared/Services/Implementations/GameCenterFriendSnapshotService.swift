//
//  GameCenterFriendSnapshotService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 05/04/2026.
//

import Foundation
import GameKit

public final class GameCenterFriendSnapshotService: GameCenterFriendSnapshotServicing {
    private enum Limits {
        static let pageSize = 100
        static let maxPages = 5
        static let avatarHydrationCount = 24
    }

    let avatarCache: any GameCenterAvatarCaching
    private let configuration: GameCenterFriendSnapshotConfiguration

    public init(
        configuration: GameCenterFriendSnapshotConfiguration,
        avatarCache: any GameCenterAvatarCaching
    ) {
        self.configuration = configuration
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
        guard configuration.friendLeaderboardEnabled else { return [] }
        #if !os(watchOS)
        var allEntries = [GameCenterRawFriendEntry]()
        var location = 1

        for _ in 0..<Limits.maxPages {
            let pageRange = NSRange(location: location, length: Limits.pageSize)
            let pageEntries = await loadRawFriendEntriesPage(from: leaderboard, range: pageRange)
            guard pageEntries.isEmpty == false else { break }
            allEntries.append(contentsOf: pageEntries)

            if pageEntries.count < Limits.pageSize {
                break
            }
            location += pageEntries.count
        }

        return allEntries
        #else
        // Unreachable at runtime: the guard above returns [] when friendLeaderboardEnabled
        // is false (the only value used on watchOS). Required for compilation because
        // loadRawFriendEntriesPage uses symbols that don't exist on watchOS.
        return []
        #endif
    }

    private func buildFriendSnapshot(
        remoteBestScore: Int?,
        rawFriendEntries: [GameCenterRawFriendEntry]
    ) async -> FriendLeaderboardSnapshot? {
        var playerByID = [String: GKPlayer]()
        var entries = [FriendLeaderboardEntry]()

        for rawEntry in rawFriendEntries {
            let playerID = playerIdentifier(for: rawEntry.player)
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
            .prefix(Limits.avatarHydrationCount)
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

    private func playerIdentifier(for player: GKPlayer) -> String {
        configuration.playerIdentifier(player)
    }

    #if !os(watchOS)
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
                    let playerID = self.playerIdentifier(for: player)
                    guard playerID.isEmpty == false else { return nil }
                    let score = Int(entry.score)
                    guard score > 0 else { return nil }
                    return GameCenterRawFriendEntry(player: player, score: score)
                }
                continuation.resume(returning: mapped)
            }
        }
    }
    #endif

    private func loadAvatarData(for player: GKPlayer) async -> Data? {
        guard configuration.avatarHydrationEnabled else { return nil }
        let playerID = playerIdentifier(for: player)
        if let cached = await avatarCache.data(for: playerID) {
            return cached
        }
        // GKPlayer.loadPhoto is unavailable on watchOS; avatarHydrationEnabled guards
        // against reaching this point, and the #if ensures it compiles on watchOS too.
        #if !os(watchOS)
        guard #available(iOS 14.0, tvOS 14.0, macOS 11.0, *) else {
            return nil
        }
        return await loadAvatarDataIfAvailable(for: player, playerID: playerID)
        #else
        return nil
        #endif
    }

}
