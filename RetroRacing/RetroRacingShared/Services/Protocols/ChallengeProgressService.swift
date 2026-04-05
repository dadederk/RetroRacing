//
//  ChallengeProgressService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Completed-run payload used to update local challenge progress.
public struct CompletedRunChallengeData: Sendable, Equatable {
    public let overtakes: Int
    public let usedControls: Set<ChallengeControlInput>
    public let completedAt: Date
    public let activeAssistiveTechnologies: Set<ChallengeAssistiveTechnology>

    public init(
        overtakes: Int,
        usedControls: Set<ChallengeControlInput>,
        completedAt: Date = Date(),
        activeAssistiveTechnologies: Set<ChallengeAssistiveTechnology> = []
    ) {
        self.overtakes = overtakes
        self.usedControls = usedControls
        self.completedAt = completedAt
        self.activeAssistiveTechnologies = activeAssistiveTechnologies
    }
}

public struct ChallengeProgressUpdate: Sendable, Equatable {
    public let snapshot: ChallengeProgressSnapshot
    public let newlyAchievedChallengeIDs: Set<ChallengeIdentifier>

    public init(
        snapshot: ChallengeProgressSnapshot,
        newlyAchievedChallengeIDs: Set<ChallengeIdentifier>
    ) {
        self.snapshot = snapshot
        self.newlyAchievedChallengeIDs = newlyAchievedChallengeIDs
    }
}

/// Coordinates backfill and per-run updates for local challenge progress.
public protocol ChallengeProgressService {
    func performInitialBackfillIfNeeded()
    @discardableResult
    func recordCompletedRun(_ run: CompletedRunChallengeData) -> ChallengeProgressUpdate
    func replayAchievedChallenges()
    func currentProgress() -> ChallengeProgressSnapshot
}
