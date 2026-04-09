//
//  NoOpAchievementMetadataService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 09/04/2026.
//

import Foundation

/// No-op achievement metadata service used in tests and previews.
/// Always returns an empty cache so views fall back to local strings.
public struct NoOpAchievementMetadataService: AchievementMetadataService {
    public init() {}

    public func fetchAllMetadata() async -> [String: AchievementMetadata] {
        [:]
    }

    public func invalidate() async {}
}
