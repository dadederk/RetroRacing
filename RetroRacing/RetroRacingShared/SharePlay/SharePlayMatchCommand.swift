//
//  SharePlayMatchCommand.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 22/07/2026.
//

import Foundation

/// Wire messages exchanged between the two SharePlay participants via `GroupSessionMessenger`.
/// Kept `Codable` + `Sendable` so the transport layer can send/receive them without any
/// GroupActivities-specific types leaking into shared, platform-agnostic code.
public enum SharePlayMatchCommand: Sendable, Equatable, Codable {
    /// Sent by each participant once they are ready to play (session joined, UI presented).
    case sessionReady
    /// Sent by the host once both participants are ready. Carries the authoritative
    /// start timestamp (for the synchronized countdown) and the shared round difficulty.
    case roundStart(startAt: Date, difficulty: GameDifficulty)
    /// Sent whenever the sender's live score or remaining lives change during a round.
    case scoreUpdate(score: Int, lives: Int)
    /// Sent once when the sender's local run ends (collision/game over), carrying the final score.
    case playerEliminated(finalScore: Int)
    /// Sent by whichever participant computes the round result first, so the other device can
    /// mirror the exact same value without recomputing scores from potentially stale local state.
    case roundResult(SharePlayRoundResult)
    /// Sent when the sender taps Retry after a finished round.
    case retryReady
    /// Sent when leaving the session normally (not via disconnect).
    case sessionFinished
    /// Sent when aborting the match (e.g. after a retry timeout with no recovery).
    case sessionAborted(reason: SharePlayAbortReason)

    /// Default lives at round start; used when decoding legacy score-only updates.
    public static let defaultStartingLives = 3

    /// Stable, privacy-safe label for structured diagnostics. Payloads are intentionally omitted
    /// because command order matters more than command contents for lifecycle debugging.
    public var diagnosticName: String {
        switch self {
        case .sessionReady: return "sessionReady"
        case .roundStart: return "roundStart"
        case .scoreUpdate: return "scoreUpdate"
        case .playerEliminated: return "playerEliminated"
        case .roundResult: return "roundResult"
        case .retryReady: return "retryReady"
        case .sessionFinished: return "sessionFinished"
        case .sessionAborted: return "sessionAborted"
        }
    }

    private enum CodingKeys: String, CodingKey {
        case kind
        case startAt
        case difficulty
        case score
        case lives
        case finalScore
        case roundResult
        case abortReason
    }

    private enum Kind: String, Codable {
        case sessionReady, roundStart, scoreUpdate, playerEliminated, roundResult, retryReady, sessionFinished, sessionAborted
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        switch try container.decode(Kind.self, forKey: .kind) {
        case .sessionReady:
            self = .sessionReady
        case .roundStart:
            self = .roundStart(
                startAt: try container.decode(Date.self, forKey: .startAt),
                difficulty: try container.decode(GameDifficulty.self, forKey: .difficulty)
            )
        case .scoreUpdate:
            let score = try container.decode(Int.self, forKey: .score)
            let lives = try container.decodeIfPresent(Int.self, forKey: .lives) ?? Self.defaultStartingLives
            self = .scoreUpdate(score: score, lives: lives)
        case .playerEliminated:
            self = .playerEliminated(finalScore: try container.decode(Int.self, forKey: .finalScore))
        case .roundResult:
            self = .roundResult(try container.decode(SharePlayRoundResult.self, forKey: .roundResult))
        case .retryReady:
            self = .retryReady
        case .sessionFinished:
            self = .sessionFinished
        case .sessionAborted:
            self = .sessionAborted(reason: try container.decode(SharePlayAbortReason.self, forKey: .abortReason))
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        switch self {
        case .sessionReady:
            try container.encode(Kind.sessionReady, forKey: .kind)
        case .roundStart(let startAt, let difficulty):
            try container.encode(Kind.roundStart, forKey: .kind)
            try container.encode(startAt, forKey: .startAt)
            try container.encode(difficulty, forKey: .difficulty)
        case .scoreUpdate(let score, let lives):
            try container.encode(Kind.scoreUpdate, forKey: .kind)
            try container.encode(score, forKey: .score)
            try container.encode(lives, forKey: .lives)
        case .playerEliminated(let finalScore):
            try container.encode(Kind.playerEliminated, forKey: .kind)
            try container.encode(finalScore, forKey: .finalScore)
        case .roundResult(let result):
            try container.encode(Kind.roundResult, forKey: .kind)
            try container.encode(result, forKey: .roundResult)
        case .retryReady:
            try container.encode(Kind.retryReady, forKey: .kind)
        case .sessionFinished:
            try container.encode(Kind.sessionFinished, forKey: .kind)
        case .sessionAborted(let reason):
            try container.encode(Kind.sessionAborted, forKey: .kind)
            try container.encode(reason, forKey: .abortReason)
        }
    }
}
