//
//  UserDefaultsRelayedWatchBestScoreStore.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// UserDefaults-backed pending store for watch best scores relayed to companion iPhone.
public final class UserDefaultsRelayedWatchBestScoreStore: RelayedWatchBestScoreStore {
    private let userDefaults: UserDefaults
    private let keyPrefix: String
    private let queue = DispatchQueue(label: "com.retroracing.watchRelay.pendingBest")

    public init(
        userDefaults: UserDefaults,
        keyPrefix: String
    ) {
        self.userDefaults = userDefaults
        self.keyPrefix = keyPrefix
    }

    public func pendingBestScore(for difficulty: GameDifficulty) -> Int? {
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
