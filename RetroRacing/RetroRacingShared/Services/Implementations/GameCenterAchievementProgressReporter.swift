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

    public init(
        isAuthenticatedProvider: @escaping () -> Bool = { GKLocalPlayer.local.isAuthenticated }
    ) {
        self.isAuthenticatedProvider = isAuthenticatedProvider
    }

    public func reportAchievedAchievements(_ achievementIDs: Set<AchievementIdentifier>) {
        guard achievementIDs.isEmpty == false else { return }

        guard isAuthenticatedProvider() else {
            AppLog.info(
                AppLog.game + AppLog.achievement + AppLog.leaderboard,
                "🏅 Skipped achievement report – player not authenticated"
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
                    AppLog.game + AppLog.achievement + AppLog.leaderboard,
                    "🏅 Reported achieved achievements to Game Center: \(ids)"
                )
            } catch {
                let nsError = error as NSError
                AppLog.error(
                    AppLog.game + AppLog.achievement + AppLog.leaderboard,
                    "🏅 Failed reporting achievements: \(error.localizedDescription) (domain: \(nsError.domain), code: \(nsError.code))"
                )
            }
        }
    }
}
