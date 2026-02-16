//
//  LeaderboardConfiguration.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import SwiftUI

/// Platform-specific leaderboard identifier mapping by speed level.
public protocol LeaderboardConfiguration {
    func leaderboardID(for difficulty: GameDifficulty) -> String
}

public extension LeaderboardConfiguration {
    var leaderboardID: String {
        leaderboardID(for: .defaultDifficulty)
    }
}

public struct LeaderboardPlatformConfig {
    public let leaderboardID: String
    public let authenticateHandlerSetter: AuthenticateHandlerSetter?

    public init(leaderboardID: String, authenticateHandlerSetter: AuthenticateHandlerSetter?) {
        self.leaderboardID = leaderboardID
        self.authenticateHandlerSetter = authenticateHandlerSetter
    }
}

public struct ThemePlatformConfig {
    public let defaultThemeID: String
    public let availableThemes: [GameTheme]

    public init(defaultThemeID: String, availableThemes: [GameTheme]) {
        self.defaultThemeID = defaultThemeID
        self.availableThemes = availableThemes
    }
}

public struct HapticsPlatformConfig {
    public let supportsHaptics: Bool
    public let controllerProvider: () -> HapticFeedbackController

    public init(supportsHaptics: Bool, controllerProvider: @escaping () -> HapticFeedbackController) {
        self.supportsHaptics = supportsHaptics
        self.controllerProvider = controllerProvider
    }
}
