//
//  AchievementProgressReporter.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

public enum CompletedAchievementLookupResult: Sendable, Equatable {
    case completed(Set<AchievementIdentifier>)
    case unavailable
}

/// Reporting abstraction for newly achieved achievements.
public protocol AchievementProgressReporter {
    func reportAchievedAchievements(_ achievementIDs: Set<AchievementIdentifier>)
    func completedAchievementIDs() async -> CompletedAchievementLookupResult
}

public extension AchievementProgressReporter {
    func completedAchievementIDs() async -> CompletedAchievementLookupResult {
        .completed([])
    }
}
