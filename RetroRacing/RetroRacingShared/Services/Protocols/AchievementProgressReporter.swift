//
//  AchievementProgressReporter.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Reporting abstraction for newly achieved achievements.
public protocol AchievementProgressReporter {
    func reportAchievedAchievements(_ achievementIDs: Set<AchievementIdentifier>)
}
