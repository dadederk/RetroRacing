//
//  ChallengeProgressReporter.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Reporting abstraction for newly achieved challenges.
public protocol ChallengeProgressReporter {
    func reportAchievedChallenges(_ challengeIDs: Set<ChallengeIdentifier>)
}
