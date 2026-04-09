//
//  AchievementMetadataService+Environment.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 09/04/2026.
//

import SwiftUI

// MARK: - Environment Key

private struct AchievementMetadataServiceKey: EnvironmentKey {
    static let defaultValue: (any AchievementMetadataService)? = nil
}

extension EnvironmentValues {
    /// Access the current `AchievementMetadataService` from the environment.
    /// Returns `nil` if not provided; views should fall back to local strings.
    public var achievementMetadataService: (any AchievementMetadataService)? {
        get { self[AchievementMetadataServiceKey.self] }
        set { self[AchievementMetadataServiceKey.self] = newValue }
    }
}

// MARK: - View Extension

extension View {
    /// Injects an `AchievementMetadataService` into the environment for descendant views.
    public func achievementMetadataService(_ service: (any AchievementMetadataService)?) -> some View {
        environment(\.achievementMetadataService, service)
    }
}
