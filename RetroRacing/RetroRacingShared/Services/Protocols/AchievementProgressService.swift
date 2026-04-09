//
//  AchievementProgressService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Completed-run payload used to update local achievement progress.
public struct CompletedRunAchievementData: Sendable, Equatable {
    public let overtakes: Int
    public let usedControls: Set<AchievementControlInput>
    public let completedAt: Date
    public let activeAssistiveTechnologies: Set<AchievementAssistiveTechnology>

    public init(
        overtakes: Int,
        usedControls: Set<AchievementControlInput>,
        completedAt: Date = Date(),
        activeAssistiveTechnologies: Set<AchievementAssistiveTechnology> = []
    ) {
        self.overtakes = overtakes
        self.usedControls = usedControls
        self.completedAt = completedAt
        self.activeAssistiveTechnologies = activeAssistiveTechnologies
    }
}

public struct AchievementProgressUpdate: Sendable, Equatable {
    public let snapshot: AchievementProgressSnapshot
    public let newlyAchievedAchievementIDs: Set<AchievementIdentifier>

    public init(
        snapshot: AchievementProgressSnapshot,
        newlyAchievedAchievementIDs: Set<AchievementIdentifier>
    ) {
        self.snapshot = snapshot
        self.newlyAchievedAchievementIDs = newlyAchievedAchievementIDs
    }
}

/// Coordinates backfill and per-run updates for local achievement progress.
public protocol AchievementProgressService {
    func performInitialBackfillIfNeeded()
    @discardableResult
    func recordCompletedRun(_ run: CompletedRunAchievementData) -> AchievementProgressUpdate
    func replayAchievedAchievements()
    func currentProgress() -> AchievementProgressSnapshot
}
