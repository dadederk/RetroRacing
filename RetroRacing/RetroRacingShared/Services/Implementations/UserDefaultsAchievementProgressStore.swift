//
//  UserDefaultsAchievementProgressStore.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// UserDefaults-backed implementation of `AchievementProgressStore`.
///
/// No explicit synchronisation is required here because `load()` and `save()` are always
/// called from `LocalAchievementProgressService`, which is exclusively used from
/// `@MainActor`-isolated contexts (`GameViewModel`, app init, auth-change `Task` handlers).
/// `UserDefaults` read/write operations are individually atomic.
public final class UserDefaultsAchievementProgressStore: AchievementProgressStore {
    private let userDefaults: UserDefaults
    private let key: String

    public init(
        userDefaults: UserDefaults,
        key: String = "achievementProgress.snapshot.v1"
    ) {
        self.userDefaults = userDefaults
        self.key = key
    }

    public func load() -> AchievementProgressSnapshot {
        guard let data = userDefaults.data(forKey: key),
              let snapshot = try? JSONDecoder().decode(AchievementProgressSnapshot.self, from: data) else {
            return .empty
        }
        return snapshot
    }

    public func save(_ snapshot: AchievementProgressSnapshot) {
        guard let data = try? JSONEncoder().encode(snapshot) else {
            AppLog.error(
                AppLog.achievement + AppLog.game,
                "ACHIEVEMENT_SNAPSHOT_SAVE",
                outcome: .failed,
                fields: [.reason("encoding_failed")]
            )
            return
        }
        userDefaults.set(data, forKey: key)
    }
}
