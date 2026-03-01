//
//  UserDefaultsChallengeProgressStore.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// UserDefaults-backed implementation of `ChallengeProgressStore`.
public final class UserDefaultsChallengeProgressStore: ChallengeProgressStore {
    private let userDefaults: UserDefaults
    private let key: String
    private let queue = DispatchQueue(label: "com.retroracing.challengeprogress")

    public init(
        userDefaults: UserDefaults,
        key: String = "challengeProgress.snapshot.v1"
    ) {
        self.userDefaults = userDefaults
        self.key = key
    }

    public func load() -> ChallengeProgressSnapshot {
        queue.sync {
            guard let data = userDefaults.data(forKey: key),
                  let snapshot = try? JSONDecoder().decode(ChallengeProgressSnapshot.self, from: data) else {
                return .empty
            }
            return snapshot
        }
    }

    public func save(_ snapshot: ChallengeProgressSnapshot) {
        queue.sync {
            guard let data = try? JSONEncoder().encode(snapshot) else {
                AppLog.error(AppLog.game + AppLog.challenge, "🏅 Failed to encode challenge snapshot for persistence")
                return
            }
            userDefaults.set(data, forKey: key)
        }
    }
}
