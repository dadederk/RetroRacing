//
//  ChallengeProgressSnapshot.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Persisted local progress used for retroactive challenge unlocks.
public struct ChallengeProgressSnapshot: Codable, Equatable, Sendable {
    public var bestRunOvertakes: Int
    public var cumulativeOvertakes: Int
    public var lifetimeUsedControls: Set<ChallengeControlInput>
    /// Persisted as optional to preserve backward compatibility with older snapshots.
    public var gaadAssistiveRunCompleted: Bool?
    public var achievedChallengeIDs: Set<ChallengeIdentifier>
    public var backfillVersion: Int?

    public init(
        bestRunOvertakes: Int = 0,
        cumulativeOvertakes: Int = 0,
        lifetimeUsedControls: Set<ChallengeControlInput> = [],
        gaadAssistiveRunCompleted: Bool? = nil,
        achievedChallengeIDs: Set<ChallengeIdentifier> = [],
        backfillVersion: Int? = nil
    ) {
        self.bestRunOvertakes = bestRunOvertakes
        self.cumulativeOvertakes = cumulativeOvertakes
        self.lifetimeUsedControls = lifetimeUsedControls
        self.gaadAssistiveRunCompleted = gaadAssistiveRunCompleted
        self.achievedChallengeIDs = achievedChallengeIDs
        self.backfillVersion = backfillVersion
    }

    public static let empty = ChallengeProgressSnapshot()
}
