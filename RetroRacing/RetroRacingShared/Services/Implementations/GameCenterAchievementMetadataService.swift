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
    var cache: [String: AchievementMetadata]?
    var descriptionCache: [String: GKAchievementDescription]?
    var artworkCache = [String: Data]()
    var cacheGeneration: UInt64 = 0
    private var fetchTask: Task<LoadedAchievementDescriptions, Never>?
    var artworkFetchTasks = [String: Task<Data?, Never>]()
    let isAuthenticatedProvider: @Sendable () -> Bool

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

        let generation = cacheGeneration

        if let existing = fetchTask {
            let loaded = await existing.value
            guard cacheGeneration == generation else { return [:] }
            if cache == nil || cache?.isEmpty == true {
                cache = loaded.metadata
                descriptionCache = loaded.descriptions
            }
            return cache ?? [:]
        }

        let task = Task<LoadedAchievementDescriptions, Never> {
            await loadFromGameCenter()
        }
        fetchTask = task
        let result = await task.value
        guard cacheGeneration == generation else { return [:] }
        // After the suspension point the actor may have been re-entered (e.g. invalidate() was
        // called while we were waiting on the GK callback). If that happened, cache is already
        // nil and the next caller will start a fresh fetch — writing the result here is safe
        // because the empty-cache guard at the top of fetchAllMetadata() triggers a re-fetch.
        if cache == nil || cache?.isEmpty == true {
            cache = result.metadata
            descriptionCache = result.descriptions
        }
        fetchTask = nil
        return cache ?? [:]
    }

    public func invalidate() {
        cacheGeneration &+= 1
        cache = nil
        descriptionCache = nil
        artworkCache.removeAll()
        fetchTask?.cancel()
        fetchTask = nil
        for task in artworkFetchTasks.values {
            task.cancel()
        }
        artworkFetchTasks.removeAll()
        AppLog.info(
            AppLog.achievement + AppLog.leaderboard,
            "ACHIEVEMENT_METADATA_CACHE",
            outcome: .completed,
            fields: [.reason("invalidated")]
        )
    }

    private struct LoadedAchievementDescriptions {
        let metadata: [String: AchievementMetadata]
        let descriptions: [String: GKAchievementDescription]
    }

    private func loadFromGameCenter() async -> LoadedAchievementDescriptions {
        guard isAuthenticatedProvider() else {
            AppLog.info(
                AppLog.achievement + AppLog.leaderboard,
                "ACHIEVEMENT_METADATA_LOAD",
                outcome: .blocked,
                fields: [.reason("player_not_authenticated")]
            )
            return LoadedAchievementDescriptions(metadata: [:], descriptions: [:])
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
                    continuation.resume(returning: LoadedAchievementDescriptions(metadata: [:], descriptions: [:]))
                    return
                }

                guard let descriptions else {
                    AppLog.info(
                        AppLog.achievement + AppLog.leaderboard,
                        "ACHIEVEMENT_METADATA_LOAD",
                        outcome: .skipped,
                        fields: [.reason("descriptions_nil")]
                    )
                    continuation.resume(returning: LoadedAchievementDescriptions(metadata: [:], descriptions: [:]))
                    return
                }

                var result = [String: AchievementMetadata]()
                var descriptionsByID = [String: GKAchievementDescription]()
                for description in descriptions {
                    descriptionsByID[description.identifier] = description
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
                continuation.resume(
                    returning: LoadedAchievementDescriptions(
                        metadata: result,
                        descriptions: descriptionsByID
                    )
                )
            }
        }
    }
}
