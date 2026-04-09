//
//  UserDefaultsPendingLeaderboardScoreStore.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 09/04/2026.
//

import Foundation

/// UserDefaults-backed store for leaderboard scores that could not be submitted because
/// the player was not authenticated at the time of the game over.
///
/// `@unchecked Sendable`: all stored properties are immutable `let` references.
/// `UserDefaults` is thread-safe per Apple documentation, and `DispatchQueue.sync`
/// provides additional serialization for the read-modify-write in `updatePendingBestScoreIfHigher`.
public final class UserDefaultsPendingLeaderboardScoreStore: @unchecked Sendable, PendingLeaderboardScoreStore {
    private let userDefaults: UserDefaults
    private let keyPrefix: String
    private let queue = DispatchQueue(label: "com.retroracing.pendingLeaderboardScore")

    public init(
        userDefaults: UserDefaults,
        keyPrefix: String = "pendingLeaderboardScore"
    ) {
        self.userDefaults = userDefaults
        self.keyPrefix = keyPrefix
    }

    public func bestPendingScore(for difficulty: GameDifficulty) -> Int? {
        queue.sync {
            let key = pendingKey(for: difficulty)
            guard userDefaults.object(forKey: key) != nil else { return nil }
            return userDefaults.integer(forKey: key)
        }
    }

    @discardableResult
    public func updatePendingBestScoreIfHigher(_ score: Int, for difficulty: GameDifficulty) -> Bool {
        queue.sync {
            let key = pendingKey(for: difficulty)
            let existing = userDefaults.object(forKey: key) != nil ? userDefaults.integer(forKey: key) : Int.min
            guard score > existing else { return false }
            userDefaults.set(score, forKey: key)
            return true
        }
    }

    public func clearPendingBestScore(for difficulty: GameDifficulty) {
        queue.sync {
            userDefaults.removeObject(forKey: pendingKey(for: difficulty))
        }
    }

    public func pendingDifficulties() -> [GameDifficulty] {
        queue.sync {
            GameDifficulty.allCases.filter { difficulty in
                userDefaults.object(forKey: pendingKey(for: difficulty)) != nil
            }
        }
    }

    private func pendingKey(for difficulty: GameDifficulty) -> String {
        "\(keyPrefix).\(difficulty.rawValue)"
    }
}
