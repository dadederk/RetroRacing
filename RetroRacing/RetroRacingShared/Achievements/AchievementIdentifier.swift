//
//  AchievementIdentifier.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Stable local identifiers for achievement progress tracking.
/// IDs are prefixed with the main app bundle identifier plus `.achievement` for Game Center / ASC alignment.
public enum AchievementIdentifier: String, CaseIterable, Sendable {
    /// Prefix shared by all achievement IDs: `{mainBundleId}.achievement`.
    public static let achievementIdentifierPrefix = "com.accessibilityUpTo11.RetroRacing.achievement"

    // Overtakes in a single completed run (user-facing batch: Streak)
    case runOvertakes100 = "com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0100"
    case runOvertakes200 = "com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0200"
    case runOvertakes300 = "com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0300"
    case runOvertakes400 = "com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0400"
    case runOvertakes500 = "com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0500"
    case runOvertakes600 = "com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0600"
    case runOvertakes700 = "com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0700"
    case runOvertakes800 = "com.accessibilityUpTo11.RetroRacing.achievement.run.overtakes.0800"

    // Lifetime cumulative overtakes (user-facing batch: Overlander)
    case totalOvertakes1k = "com.accessibilityUpTo11.RetroRacing.achievement.total.overtakes.001k"
    case totalOvertakes5k = "com.accessibilityUpTo11.RetroRacing.achievement.total.overtakes.005k"
    case totalOvertakes10k = "com.accessibilityUpTo11.RetroRacing.achievement.total.overtakes.010k"
    case totalOvertakes20k = "com.accessibilityUpTo11.RetroRacing.achievement.total.overtakes.020k"
    case totalOvertakes50k = "com.accessibilityUpTo11.RetroRacing.achievement.total.overtakes.050k"
    case totalOvertakes100k = "com.accessibilityUpTo11.RetroRacing.achievement.total.overtakes.100k"
    case totalOvertakes200k = "com.accessibilityUpTo11.RetroRacing.achievement.total.overtakes.200k"

    // Control-based achievements
    case controlTap = "com.accessibilityUpTo11.RetroRacing.achievement.control.tap"
    case controlSwipe = "com.accessibilityUpTo11.RetroRacing.achievement.control.swipe"
    case controlKeyboard = "com.accessibilityUpTo11.RetroRacing.achievement.control.keyboard"
    case controlVoiceOver = "com.accessibilityUpTo11.RetroRacing.achievement.control.voiceover"
    case controlDigitalCrown = "com.accessibilityUpTo11.RetroRacing.achievement.control.crown"
    case controlGameController = "com.accessibilityUpTo11.RetroRacing.achievement.control.gamecontroller"

    // Event-based achievements
    case eventGAADAssistive = "com.accessibilityUpTo11.RetroRacing.achievement.event.gaad.assistive"

    /// Resolves a stored raw value from UserDefaults or debug settings.
    public static func resolvedFromStoredRawValue(_ raw: String) -> AchievementIdentifier? {
        guard raw.isEmpty == false else { return nil }
        return AchievementIdentifier(rawValue: raw)
    }
}

extension AchievementIdentifier: Identifiable {
    public var id: String { rawValue }
}

extension AchievementIdentifier: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if let value = AchievementIdentifier(rawValue: raw) {
            self = value
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown achievement identifier: \(raw)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}
