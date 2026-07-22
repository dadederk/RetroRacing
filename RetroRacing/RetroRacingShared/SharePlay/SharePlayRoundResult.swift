//
//  SharePlayRoundResult.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation

/// Final, mirrored result of a SharePlay round. Both participants converge on the exact
/// same value so the result screen always shows identical win/lose/tie state and scores.
public struct SharePlayRoundResult: Sendable, Equatable, Codable {
    public let hostScore: Int
    public let guestScore: Int
    public let difficulty: GameDifficulty

    public init(hostScore: Int, guestScore: Int, difficulty: GameDifficulty) {
        self.hostScore = hostScore
        self.guestScore = guestScore
        self.difficulty = difficulty
    }

    /// Outcome from a neutral (host vs. guest) perspective.
    public enum Outcome: Sendable, Equatable {
        case hostWon
        case guestWon
        case tie
    }

    /// Outcome from the perspective of a given local role. Ties are allowed per product decision.
    public enum LocalOutcome: Sendable, Equatable {
        case won
        case lost
        case tie
    }

    public var outcome: Outcome {
        if hostScore > guestScore { return .hostWon }
        if guestScore > hostScore { return .guestWon }
        return .tie
    }

    public func localOutcome(for role: SharePlayPlayerRole) -> LocalOutcome {
        switch (outcome, role) {
        case (.tie, _):
            return .tie
        case (.hostWon, .host), (.guestWon, .guest):
            return .won
        case (.hostWon, .guest), (.guestWon, .host):
            return .lost
        }
    }

    /// Score for the given role, independent of host/guest wire assignment.
    public func score(for role: SharePlayPlayerRole) -> Int {
        role == .host ? hostScore : guestScore
    }

    /// Score for the opponent of the given role.
    public func opponentScore(for role: SharePlayPlayerRole) -> Int {
        role == .host ? guestScore : hostScore
    }
}
