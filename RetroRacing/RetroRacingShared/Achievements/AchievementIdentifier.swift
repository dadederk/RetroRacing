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

public extension AchievementIdentifier {
    var localizedTitle: String {
        if let threshold = runOvertakesThreshold {
            return GameLocalizedStrings.format("achievement_title_run_overtakes %lld", Int64(threshold))
        }
        if let threshold = totalOvertakesThreshold {
            return GameLocalizedStrings.format("achievement_title_total_overtakes %lld", Int64(threshold))
        }
        if let controlName = localizedControlName {
            return GameLocalizedStrings.format("achievement_title_control %@", controlName)
        }
        return GameLocalizedStrings.string("achievement_title_event_gaad")
    }

    private var runOvertakesThreshold: Int? {
        switch self {
        case .runOvertakes100:
            return 100
        case .runOvertakes200:
            return 200
        case .runOvertakes300:
            return 300
        case .runOvertakes400:
            return 400
        case .runOvertakes500:
            return 500
        case .runOvertakes600:
            return 600
        case .runOvertakes700:
            return 700
        case .runOvertakes800:
            return 800
        default:
            return nil
        }
    }

    private var totalOvertakesThreshold: Int? {
        switch self {
        case .totalOvertakes1k:
            return 1_000
        case .totalOvertakes5k:
            return 5_000
        case .totalOvertakes10k:
            return 10_000
        case .totalOvertakes20k:
            return 20_000
        case .totalOvertakes50k:
            return 50_000
        case .totalOvertakes100k:
            return 100_000
        case .totalOvertakes200k:
            return 200_000
        default:
            return nil
        }
    }

    private var localizedControlName: String? {
        switch self {
        case .controlTap:
            return GameLocalizedStrings.string("achievement_control_name_tap")
        case .controlSwipe:
            return GameLocalizedStrings.string("achievement_control_name_swipe")
        case .controlKeyboard:
            return GameLocalizedStrings.string("achievement_control_name_keyboard")
        case .controlVoiceOver:
            return GameLocalizedStrings.string("achievement_control_name_voiceover")
        case .controlDigitalCrown:
            return GameLocalizedStrings.string("achievement_control_name_crown")
        case .controlGameController:
            return GameLocalizedStrings.string("achievement_control_name_gamecontroller")
        default:
            return nil
        }
    }
}
