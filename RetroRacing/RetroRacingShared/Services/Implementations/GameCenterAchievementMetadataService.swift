//
//  GameCenterAchievementMetadataService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 09/04/2026.
//

import Foundation
import GameKit

/// Game Center-backed achievement metadata service.
///
/// Fetches `GKAchievementDescription` objects on first call and caches the result for the
/// lifetime of the process. Concurrent calls while a fetch is in-flight wait for the same
/// result rather than issuing duplicate requests. Skips the fetch when the local player is
/// not authenticated and returns an empty cache instead.
public actor GameCenterAchievementMetadataService: AchievementMetadataService {
    private var cache: [String: AchievementMetadata]?
    private var fetchTask: Task<[String: AchievementMetadata], Never>?
    private let isAuthenticatedProvider: @Sendable () -> Bool

    public init(
        isAuthenticatedProvider: @escaping @Sendable () -> Bool = { GKLocalPlayer.local.isAuthenticated }
    ) {
        self.isAuthenticatedProvider = isAuthenticatedProvider
    }

    public func fetchAllMetadata() async -> [String: AchievementMetadata] {
        // Return non-empty cache immediately. An empty cache might mean the player was not
        // authenticated on the previous attempt, so we re-fetch after invalidate() is called.
        if let cache, cache.isEmpty == false {
            return cache
        }

        if let existing = fetchTask {
            return await existing.value
        }

        let task = Task<[String: AchievementMetadata], Never> {
            await loadFromGameCenter()
        }
        fetchTask = task
        let result = await task.value
        // After the suspension point the actor may have been re-entered (e.g. invalidate() was
        // called while we were waiting on the GK callback). If that happened, cache is already
        // nil and the next caller will start a fresh fetch — writing the result here is safe
        // because the empty-cache guard at the top of fetchAllMetadata() triggers a re-fetch.
        cache = result
        fetchTask = nil
        return result
    }

    public func invalidate() {
        cache = nil
        fetchTask?.cancel()
        fetchTask = nil
        AppLog.info(
            AppLog.achievement + AppLog.leaderboard,
            "ACHIEVEMENT_METADATA_CACHE",
            outcome: .completed,
            fields: [.reason("invalidated")]
        )
    }

    private func loadFromGameCenter() async -> [String: AchievementMetadata] {
        guard isAuthenticatedProvider() else {
            AppLog.info(
                AppLog.achievement + AppLog.leaderboard,
                "ACHIEVEMENT_METADATA_LOAD",
                outcome: .blocked,
                fields: [.reason("player_not_authenticated")]
            )
            return [:]
        }

        return await withCheckedContinuation { continuation in
            GKAchievementDescription.loadAchievementDescriptions { descriptions, error in
                if let error {
                    AppLog.error(
                        AppLog.achievement + AppLog.leaderboard,
                        "ACHIEVEMENT_METADATA_LOAD",
                        outcome: .failed,
                        fields: [.reason("gamekit_error")] + AppLog.Field.error(error)
                    )
                    continuation.resume(returning: [:])
                    return
                }

                guard let descriptions else {
                    AppLog.info(
                        AppLog.achievement + AppLog.leaderboard,
                        "ACHIEVEMENT_METADATA_LOAD",
                        outcome: .skipped,
                        fields: [.reason("descriptions_nil")]
                    )
                    continuation.resume(returning: [:])
                    return
                }

                var result = [String: AchievementMetadata]()
                for description in descriptions {
                    result[description.identifier] = AchievementMetadata(
                        title: description.title,
                        achievedDescription: description.achievedDescription,
                        unachievedDescription: description.unachievedDescription
                    )
                }

                AppLog.info(
                    AppLog.achievement + AppLog.leaderboard,
                    "ACHIEVEMENT_METADATA_LOAD",
                    outcome: .succeeded,
                    fields: [.int("count", result.count)]
                )
                continuation.resume(returning: result)
            }
        }
    }
}
