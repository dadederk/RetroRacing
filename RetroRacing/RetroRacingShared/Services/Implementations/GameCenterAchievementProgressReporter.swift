//
//  GameCenterAchievementProgressReporter.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 09/04/2026.
//

import Foundation
import GameKit

/// Game Center-backed achievement reporter.
public struct GameCenterAchievementProgressReporter: AchievementProgressReporter {
    private let isAuthenticatedProvider: () -> Bool
    private let completedAchievementIDProvider: () async throws -> Set<String>

    public init(
        isAuthenticatedProvider: @escaping () -> Bool = { GKLocalPlayer.local.isAuthenticated },
        completedAchievementIDProvider: (() async throws -> Set<String>)? = nil
    ) {
        self.isAuthenticatedProvider = isAuthenticatedProvider
        self.completedAchievementIDProvider = completedAchievementIDProvider ?? Self.loadCompletedGameCenterAchievementIDs
    }

    public func reportAchievedAchievements(_ achievementIDs: Set<AchievementIdentifier>) {
        guard achievementIDs.isEmpty == false else { return }

        guard isAuthenticatedProvider() else {
            AppLog.info(
                AppLog.achievement + AppLog.leaderboard,
                "ACHIEVEMENT_REPORT",
                outcome: .blocked,
                fields: [.reason("player_not_authenticated")]
            )
            return
        }

        let achievements = achievementIDs.map { achievementID in
            let achievement = GKAchievement(identifier: achievementID.rawValue)
            achievement.percentComplete = 100
            achievement.showsCompletionBanner = true
            return achievement
        }

        Task {
            do {
                try await GKAchievement.report(achievements)
                let ids = achievementIDs.map(\.rawValue).sorted().joined(separator: ", ")
                AppLog.info(
                    AppLog.achievement + AppLog.leaderboard,
                    "ACHIEVEMENT_REPORT",
                    outcome: .succeeded,
                    fields: [
                        .int("count", achievementIDs.count),
                        .string("ids", ids)
                    ]
                )
            } catch {
                AppLog.error(
                    AppLog.achievement + AppLog.leaderboard,
                    "ACHIEVEMENT_REPORT",
                    outcome: .failed,
                    fields: [.reason("gamekit_error")] + AppLog.Field.error(error)
                )
            }
        }
    }

    public func completedAchievementIDs() async -> CompletedAchievementLookupResult {
        guard isAuthenticatedProvider() else {
            AppLog.info(
                AppLog.achievement + AppLog.leaderboard,
                "ACHIEVEMENT_REMOTE_SYNC",
                outcome: .blocked,
                fields: [.reason("player_not_authenticated")]
            )
            return .unavailable
        }

        do {
            let rawIDs = try await completedAchievementIDProvider()
            let completedIDs = Set(rawIDs.compactMap(AchievementIdentifier.init(rawValue:)))
            AppLog.info(
                AppLog.achievement + AppLog.leaderboard,
                "ACHIEVEMENT_REMOTE_SYNC_FETCH",
                outcome: .completed,
                fields: [
                    .int("gameCenterCount", rawIDs.count),
                    .int("knownCount", completedIDs.count)
                ]
            )
            return .completed(completedIDs)
        } catch {
            AppLog.error(
                AppLog.achievement + AppLog.leaderboard,
                "ACHIEVEMENT_REMOTE_SYNC_FETCH",
                outcome: .failed,
                fields: [.reason("gamekit_error")] + AppLog.Field.error(error)
            )
            return .unavailable
        }
    }

    private static func loadCompletedGameCenterAchievementIDs() async throws -> Set<String> {
        let achievements = try await GKAchievement.loadAchievements()
        return Set(
            achievements
                .filter { $0.isCompleted || $0.percentComplete >= 100 }
                .map(\.identifier)
        )
    }
}
