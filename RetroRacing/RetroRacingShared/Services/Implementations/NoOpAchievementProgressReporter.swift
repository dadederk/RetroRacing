//
//  NoOpAchievementProgressReporter.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Default reporter used before Game Center achievements are configured.
public struct NoOpAchievementProgressReporter: AchievementProgressReporter {
    public init() {}

    public func reportAchievedAchievements(_ achievementIDs: Set<AchievementIdentifier>) {
        guard achievementIDs.isEmpty == false else { return }
        let ids = achievementIDs.map(\.rawValue).sorted().joined(separator: ", ")
        AppLog.info(AppLog.game + AppLog.achievement, "🏅 Newly achieved local achievements: \(ids)")
    }
}
