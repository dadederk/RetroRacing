//
//  WatchBestScoreRelaySender.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Queueable payload sent from watchOS to companion iPhone to relay a watch best score.
public struct WatchBestScoreRelayPayload: Sendable {
    public static let scoreKey = "score"
    public static let difficultyKey = "difficulty"
    public static let sentAtKey = "sentAt"

    public let score: Int
    public let difficultyRawValue: String
    public let sentAt: Date

    public init(score: Int, difficulty: GameDifficulty, sentAt: Date = Date()) {
        self.score = score
        self.difficultyRawValue = difficulty.rawValue
        self.sentAt = sentAt
    }

    public var difficulty: GameDifficulty? {
        GameDifficulty(rawValue: difficultyRawValue)
    }

    public var userInfo: [String: Any] {
        [
            Self.scoreKey: score,
            Self.difficultyKey: difficultyRawValue,
            Self.sentAtKey: sentAt.timeIntervalSince1970,
        ]
    }

    public static func from(userInfo: [String: Any]) -> WatchBestScoreRelayPayload? {
        guard
            let score = userInfo[scoreKey] as? Int,
            let difficultyRawValue = userInfo[difficultyKey] as? String,
            let difficulty = GameDifficulty(rawValue: difficultyRawValue),
            let sentAtEpoch = userInfo[sentAtKey] as? TimeInterval
        else {
            return nil
        }

        return WatchBestScoreRelayPayload(
            score: score,
            difficulty: difficulty,
            sentAt: Date(timeIntervalSince1970: sentAtEpoch)
        )
    }
}

/// Contract for relaying watch best scores to another process/device.
public protocol WatchBestScoreRelaySender {
    func relayBestScore(_ score: Int, difficulty: GameDifficulty)
}

public struct NoOpWatchBestScoreRelaySender: WatchBestScoreRelaySender {
    public init() {}

    public func relayBestScore(_ score: Int, difficulty: GameDifficulty) {}
}
