//
//  NoOpChallengeProgressReporter.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Default reporter used before Game Center achievements are configured.
public struct NoOpChallengeProgressReporter: ChallengeProgressReporter {
    public init() {}

    public func reportAchievedChallenges(_ challengeIDs: Set<ChallengeIdentifier>) {
        guard challengeIDs.isEmpty == false else { return }
        let ids = challengeIDs.map(\.rawValue).sorted().joined(separator: ", ")
        AppLog.info(AppLog.game + AppLog.challenge, "🏅 Newly achieved local challenges: \(ids)")
    }
}
