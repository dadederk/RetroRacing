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
    private let key: String
    private let queue = DispatchQueue(label: "com.retroracing.highestscore")

    public init(userDefaults: UserDefaults, key: String = "highestScore") {
        self.userDefaults = userDefaults
        self.key = key
    }

    public func currentBest() -> Int {
        queue.sync {
            userDefaults.integer(forKey: key)
        }
    }

    @discardableResult
    public func updateIfHigher(_ score: Int) -> Bool {
        queue.sync {
            let existing = userDefaults.integer(forKey: key)
            guard score > existing else { return false }
            userDefaults.set(score, forKey: key)
            return true
        }
    }

    public func syncFromRemote(bestScore: Int) {
        queue.sync {
            let existing = userDefaults.integer(forKey: key)
            guard bestScore > existing else { return }
            userDefaults.set(bestScore, forKey: key)
        }
    }
}
