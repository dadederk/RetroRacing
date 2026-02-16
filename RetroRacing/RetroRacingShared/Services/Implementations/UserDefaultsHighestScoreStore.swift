//
//  UserDefaultsHighestScoreStore.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// UserDefaults-backed implementation of `HighestScoreStore`.
/// Uses a dedicated key to avoid collisions; thread-safe via serial queue.
public final class UserDefaultsHighestScoreStore: HighestScoreStore {
    private let userDefaults: UserDefaults
    private let keyPrefix: String
    private let legacyRapidKey: String
    private let queue = DispatchQueue(label: "com.retroracing.highestscore")

    public init(userDefaults: UserDefaults, key: String = "highestScore") {
        self.userDefaults = userDefaults
        self.keyPrefix = key
        self.legacyRapidKey = key
    }

    public func currentBest(for difficulty: GameDifficulty) -> Int {
        queue.sync {
            currentBestLocked(for: difficulty)
        }
    }

    @discardableResult
    public func updateIfHigher(_ score: Int, for difficulty: GameDifficulty) -> Bool {
        queue.sync {
            let existing = currentBestLocked(for: difficulty)
            guard score > existing else { return false }
            let storageKey = highestScoreKey(for: difficulty)
            userDefaults.set(score, forKey: storageKey)
            if difficulty == .rapid {
                userDefaults.set(score, forKey: legacyRapidKey)
            }
            return true
        }
    }

    public func syncFromRemote(bestScore: Int, for difficulty: GameDifficulty) {
        queue.sync {
            let existing = currentBestLocked(for: difficulty)
            guard bestScore > existing else { return }
            let storageKey = highestScoreKey(for: difficulty)
            userDefaults.set(bestScore, forKey: storageKey)
            if difficulty == .rapid {
                userDefaults.set(bestScore, forKey: legacyRapidKey)
            }
        }
    }

    private func currentBestLocked(for difficulty: GameDifficulty) -> Int {
        let storageKey = highestScoreKey(for: difficulty)

        if difficulty == .rapid, userDefaults.object(forKey: storageKey) == nil {
            return userDefaults.integer(forKey: legacyRapidKey)
        }

        return userDefaults.integer(forKey: storageKey)
    }

    private func highestScoreKey(for difficulty: GameDifficulty) -> String {
        "\(keyPrefix).\(difficulty.rawValue)"
    }
}
