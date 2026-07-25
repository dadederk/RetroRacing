//
//  ScreenshotFixtureCatalog.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public enum ScreenshotFixtureCatalog {
    public static let universalSlideCount = ScreenshotSlideFixture.universalSlideCount
    public static let macSlideCount = ScreenshotSlideFixture.macSlideCount

    public static func slideCount(for platform: String?) -> Int {
        ScreenshotSlideFixture.slideCount(for: platform)
    }
    public static let gameplaySeed: UInt64 = 42_026_072_301

    public static let rivalFriendPlayerID = "screenshot-friend-ja"
    public static let rivalFriendDisplayName = "John Appleseed"
    public static let rivalFriendScore = 285
    public static let rivalFriendInitials = "JA"

    public static let gameOverRunScore = 274
    public static let gameOverPreviousBestScore = 251
    public static let gameOverBestScore = 274

    public static let friendMarkerCurrentScore = 42
    /// Middle car one row above the player (row 3, center column).
    public static let friendMarkerTargetScore = 44

    public static let hookGameplayScore = 18
    public static let actionGameplayScore = 97
    public static let actionGameplayLives = 2

    public static var rivalFriendAheadSummary: GameOverFriendAheadSummary {
        GameOverFriendAheadSummary(
            playerID: rivalFriendPlayerID,
            displayName: rivalFriendDisplayName,
            score: rivalFriendScore,
            avatarPNGData: ScreenshotFixtureAssets.johnAppleseedAvatarPNGData
        )
    }

    public static func rivalFriendMilestone() -> UpcomingFriendMilestone {
        UpcomingFriendMilestone(
            playerID: rivalFriendPlayerID,
            displayName: rivalFriendDisplayName,
            targetScore: friendMarkerTargetScore,
            avatarPNGData: ScreenshotFixtureAssets.johnAppleseedAvatarPNGData
        )
    }
}
