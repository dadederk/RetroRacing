//
//  AchievementProgressSnapshot.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Persisted local progress used for retroactive achievement unlocks.
public struct AchievementProgressSnapshot: Codable, Equatable, Sendable {
    public var bestRunOvertakes: Int
    public var cumulativeOvertakes: Int
    public var lifetimeUsedControls: Set<AchievementControlInput>
    /// Persisted as optional to preserve backward compatibility with older snapshots.
    public var gaadAssistiveRunCompleted: Bool?
    public var achievedAchievementIDs: Set<AchievementIdentifier>
    public var backfillVersion: Int?

    public init(
        bestRunOvertakes: Int = 0,
        cumulativeOvertakes: Int = 0,
        lifetimeUsedControls: Set<AchievementControlInput> = [],
        gaadAssistiveRunCompleted: Bool? = nil,
        achievedAchievementIDs: Set<AchievementIdentifier> = [],
        backfillVersion: Int? = nil
    ) {
        self.bestRunOvertakes = bestRunOvertakes
        self.cumulativeOvertakes = cumulativeOvertakes
        self.lifetimeUsedControls = lifetimeUsedControls
        self.gaadAssistiveRunCompleted = gaadAssistiveRunCompleted
        self.achievedAchievementIDs = achievedAchievementIDs
        self.backfillVersion = backfillVersion
    }

    public static let empty = AchievementProgressSnapshot()
}
