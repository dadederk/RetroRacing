//
//  AchievementProgressStore.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Persistence abstraction for local achievement progress snapshots.
public protocol AchievementProgressStore {
    func load() -> AchievementProgressSnapshot
    func save(_ snapshot: AchievementProgressSnapshot)
}
