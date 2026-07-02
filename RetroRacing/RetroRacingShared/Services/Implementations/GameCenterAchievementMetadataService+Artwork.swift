//
//  GameCenterAchievementMetadataService+Artwork.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 26/06/2026.
//

import Foundation
import GameKit

extension GameCenterAchievementMetadataService {
    public func loadArtwork(for identifier: String) async -> Data? {
        if let cached = artworkCache[identifier] {
            return cached
        }

        let generation = cacheGeneration

        if let existing = artworkFetchTasks[identifier] {
            let result = await existing.value
            guard cacheGeneration == generation else { return nil }
            return result
        }

        guard isAuthenticatedProvider() else {
            AppLog.info(
                AppLog.achievement + AppLog.leaderboard,
                "ACHIEVEMENT_ARTWORK_LOAD",
                outcome: .blocked,
                fields: [
                    .reason("player_not_authenticated"),
                    .string("achievementID", identifier)
                ]
            )
            return nil
        }

        let task = Task<Data?, Never> {
            await loadArtworkFromGameCenter(for: identifier, generation: generation)
        }
        artworkFetchTasks[identifier] = task
        let result = await task.value
        artworkFetchTasks[identifier] = nil
        guard cacheGeneration == generation else { return nil }
        if let result {
            artworkCache[identifier] = result
        }
        return result
    }

    private func loadArtworkFromGameCenter(for identifier: String, generation: UInt64) async -> Data? {
        #if os(watchOS)
        return nil
        #else
        _ = await fetchAllMetadata()
        guard cacheGeneration == generation else { return nil }

        guard let description = descriptionCache?[identifier] else {
            AppLog.info(
                AppLog.achievement + AppLog.leaderboard,
                "ACHIEVEMENT_ARTWORK_LOAD",
                outcome: .skipped,
                fields: [
                    .reason("description_not_found"),
                    .string("achievementID", identifier)
                ]
            )
            return nil
        }

        let imageData: Data? = await withCheckedContinuation { continuation in
            description.loadImage { image, error in
                if let error {
                    AppLog.error(
                        AppLog.achievement + AppLog.leaderboard,
                        "ACHIEVEMENT_ARTWORK_LOAD",
                        outcome: .failed,
                        fields: [
                            .reason("gamekit_error"),
                            .string("achievementID", identifier)
                        ] + AppLog.Field.error(error)
                    )
                    continuation.resume(returning: nil)
                    return
                }

                guard let image else {
                    AppLog.info(
                        AppLog.achievement + AppLog.leaderboard,
                        "ACHIEVEMENT_ARTWORK_LOAD",
                        outcome: .skipped,
                        fields: [
                            .reason("image_nil"),
                            .string("achievementID", identifier)
                        ]
                    )
                    continuation.resume(returning: nil)
                    return
                }

                continuation.resume(returning: GameKitImageSerialization.pngData(from: image))
            }
        }

        guard cacheGeneration == generation else { return nil }

        if imageData != nil {
            AppLog.info(
                AppLog.achievement + AppLog.leaderboard,
                "ACHIEVEMENT_ARTWORK_LOAD",
                outcome: .succeeded,
                fields: [.string("achievementID", identifier)]
            )
        }

        return imageData
        #endif
    }
}
