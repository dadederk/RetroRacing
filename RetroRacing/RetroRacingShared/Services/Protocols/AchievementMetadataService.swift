//
//  AchievementMetadataService.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 09/04/2026.
//

import Foundation

/// Metadata for a single achievement sourced from Game Center, to be shown in the unlock UI.
public struct AchievementMetadata: Sendable {
    /// The achievement title as configured in App Store Connect.
    public let title: String
    /// Description shown when the achievement has been completed.
    public let achievedDescription: String
    /// Description shown before the achievement is completed.
    public let unachievedDescription: String

    public init(title: String, achievedDescription: String, unachievedDescription: String) {
        self.title = title
        self.achievedDescription = achievedDescription
        self.unachievedDescription = unachievedDescription
    }
}

/// Fetches and caches achievement metadata from Game Center.
///
/// Calls `fetchAllMetadata()` to retrieve the full set of achievement descriptions. Implementations
/// are expected to cache the result so that repeated calls are instant. Views fall back to local
/// strings when the service returns `nil` or is not injected via the environment.
///
/// Call `invalidate()` whenever the Game Center authentication state changes so that metadata
/// that was previously unavailable (unauthenticated) is re-fetched on the next access.
public protocol AchievementMetadataService: Sendable {
    /// Returns the full cache keyed by `AchievementIdentifier.rawValue`, or an empty dictionary
    /// when Game Center is unavailable or the player is not authenticated. Implementations must
    /// cache the result: if data has already been fetched successfully, this should return immediately.
    func fetchAllMetadata() async -> [String: AchievementMetadata]

    /// Clears any cached result so the next `fetchAllMetadata()` call re-fetches from Game Center.
    /// Call this on Game Center authentication state changes.
    func invalidate() async
}
