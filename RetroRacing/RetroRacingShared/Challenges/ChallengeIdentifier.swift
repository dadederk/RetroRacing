//
//  ChallengeIdentifier.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Stable local identifiers for challenge progress tracking.
/// IDs are prefixed with the main app bundle identifier plus `.ach` for Game Center / ASC alignment.
public enum ChallengeIdentifier: String, CaseIterable, Sendable {
    /// Prefix shared by all achievement IDs: `{mainBundleId}.ach`.
    public static let challengeIdentifierPrefix = "com.accessibilityUpTo11.RetroRacing.ach"

    // Overtakes in a single completed run (user-facing batch: Streak)
    case runOvertakes100 = "com.accessibilityUpTo11.RetroRacing.ach.run.overtakes.0100"
    case runOvertakes200 = "com.accessibilityUpTo11.RetroRacing.ach.run.overtakes.0200"
    case runOvertakes500 = "com.accessibilityUpTo11.RetroRacing.ach.run.overtakes.0500"
    case runOvertakes600 = "com.accessibilityUpTo11.RetroRacing.ach.run.overtakes.0600"
    case runOvertakes700 = "com.accessibilityUpTo11.RetroRacing.ach.run.overtakes.0700"
    case runOvertakes800 = "com.accessibilityUpTo11.RetroRacing.ach.run.overtakes.0800"

    // Lifetime cumulative overtakes (user-facing batch: Overlander)
    case totalOvertakes1k = "com.accessibilityUpTo11.RetroRacing.ach.total.overtakes.001k"
    case totalOvertakes5k = "com.accessibilityUpTo11.RetroRacing.ach.total.overtakes.005k"
    case totalOvertakes10k = "com.accessibilityUpTo11.RetroRacing.ach.total.overtakes.010k"
    case totalOvertakes20k = "com.accessibilityUpTo11.RetroRacing.ach.total.overtakes.020k"
    case totalOvertakes50k = "com.accessibilityUpTo11.RetroRacing.ach.total.overtakes.050k"
    case totalOvertakes100k = "com.accessibilityUpTo11.RetroRacing.ach.total.overtakes.100k"
    case totalOvertakes200k = "com.accessibilityUpTo11.RetroRacing.ach.total.overtakes.200k"

    // Control-based challenges
    case controlTap = "com.accessibilityUpTo11.RetroRacing.ach.control.tap"
    case controlSwipe = "com.accessibilityUpTo11.RetroRacing.ach.control.swipe"
    case controlKeyboard = "com.accessibilityUpTo11.RetroRacing.ach.control.keyboard"
    case controlVoiceOver = "com.accessibilityUpTo11.RetroRacing.ach.control.voiceover"
    case controlDigitalCrown = "com.accessibilityUpTo11.RetroRacing.ach.control.crown"
    case controlGameController = "com.accessibilityUpTo11.RetroRacing.ach.control.gamecontroller"

    // Event-based challenges
    case eventGAADAssistive = "com.accessibilityUpTo11.RetroRacing.ach.event.gaad.assistive"

    /// Resolves a stored raw value from UserDefaults or debug settings, including pre-prefix legacy IDs.
    public static func resolvedFromStoredRawValue(_ raw: String) -> ChallengeIdentifier? {
        if raw.isEmpty {
            return nil
        }
        if let id = ChallengeIdentifier(rawValue: raw) {
            return id
        }
        return Self.legacyRawValueMapping[raw]
    }
}

// MARK: - Legacy IDs (pre–bundle-prefixed achievement strings)

private extension ChallengeIdentifier {
    /// Maps former `ach.*` identifiers to the current cases for decoding persisted snapshots.
    static let legacyRawValueMapping: [String: ChallengeIdentifier] = [
        "ach.run.overtakes.0100": .runOvertakes100,
        "ach.run.overtakes.0200": .runOvertakes200,
        "ach.run.overtakes.0500": .runOvertakes500,
        "ach.run.overtakes.0600": .runOvertakes600,
        "ach.run.overtakes.0700": .runOvertakes700,
        "ach.run.overtakes.0800": .runOvertakes800,
        "ach.total.overtakes.001k": .totalOvertakes1k,
        "ach.total.overtakes.005k": .totalOvertakes5k,
        "ach.total.overtakes.010k": .totalOvertakes10k,
        "ach.total.overtakes.020k": .totalOvertakes20k,
        "ach.total.overtakes.050k": .totalOvertakes50k,
        "ach.total.overtakes.100k": .totalOvertakes100k,
        "ach.total.overtakes.200k": .totalOvertakes200k,
        "ach.control.tap": .controlTap,
        "ach.control.swipe": .controlSwipe,
        "ach.control.keyboard": .controlKeyboard,
        "ach.control.voiceover": .controlVoiceOver,
        "ach.control.crown": .controlDigitalCrown,
        "ach.control.gamecontroller": .controlGameController,
        "ach.event.gaad.assistive": .eventGAADAssistive
    ]
}

extension ChallengeIdentifier: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if let value = ChallengeIdentifier(rawValue: raw) {
            self = value
        } else if let migrated = Self.legacyRawValueMapping[raw] {
            self = migrated
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown challenge identifier: \(raw)"
            )
        }
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }
}

public extension ChallengeIdentifier {
    var localizedTitle: String {
        if let threshold = runOvertakesThreshold {
            return GameLocalizedStrings.format("challenge_title_run_overtakes %lld", Int64(threshold))
        }
        if let threshold = totalOvertakesThreshold {
            return GameLocalizedStrings.format("challenge_title_total_overtakes %lld", Int64(threshold))
        }
        if let controlName = localizedControlName {
            return GameLocalizedStrings.format("challenge_title_control %@", controlName)
        }
        return GameLocalizedStrings.string("challenge_title_event_gaad")
    }

    private var runOvertakesThreshold: Int? {
        switch self {
        case .runOvertakes100:
            return 100
        case .runOvertakes200:
            return 200
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
            return GameLocalizedStrings.string("challenge_control_name_tap")
        case .controlSwipe:
            return GameLocalizedStrings.string("challenge_control_name_swipe")
        case .controlKeyboard:
            return GameLocalizedStrings.string("challenge_control_name_keyboard")
        case .controlVoiceOver:
            return GameLocalizedStrings.string("challenge_control_name_voiceover")
        case .controlDigitalCrown:
            return GameLocalizedStrings.string("challenge_control_name_crown")
        case .controlGameController:
            return GameLocalizedStrings.string("challenge_control_name_gamecontroller")
        default:
            return nil
        }
    }
}
