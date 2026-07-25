//
//  AchievementIdentifier+Localization.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 25/07/2026.
//

import Foundation

public extension AchievementIdentifier {
    /// Local fallback title aligned with App Store Connect display names.
    var localizedTitle: String {
        if let threshold = runOvertakesThreshold {
            return GameLocalizedStrings.format("achievement_title_run_overtakes %lld", Int64(threshold))
        }
        if let label = totalOvertakesTitleLabel {
            return GameLocalizedStrings.format("achievement_title_total_overtakes %@", label)
        }
        if let controlTitleKey = localizedControlTitleKey {
            return GameLocalizedStrings.string(controlTitleKey)
        }
        return GameLocalizedStrings.string("achievement_title_event_gaad")
    }

    /// Local fallback achieved description aligned with App Store Connect earned copy.
    var localizedAchievedDescription: String {
        if let threshold = runOvertakesThreshold {
            return GameLocalizedStrings.format(
                "achievement_achieved_run_overtakes %@",
                Self.formattedAchievementCount(threshold)
            )
        }
        if let threshold = totalOvertakesThreshold {
            return GameLocalizedStrings.format(
                "achievement_achieved_total_overtakes %@",
                Self.formattedAchievementCount(threshold)
            )
        }
        if let controlAchievedKey = localizedControlAchievedDescriptionKey {
            return GameLocalizedStrings.string(controlAchievedKey)
        }
        return GameLocalizedStrings.string("achievement_achieved_event_gaad")
    }

    static func formattedAchievementCount(_ value: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.locale = .autoupdatingCurrent
        return formatter.string(from: NSNumber(value: value)) ?? String(value)
    }

    private var localizedControlTitleKey: String? {
        switch self {
        case .controlTap:
            return "achievement_title_control_tap"
        case .controlSwipe:
            return "achievement_title_control_swipe"
        case .controlKeyboard:
            return "achievement_title_control_keyboard"
        case .controlVoiceOver:
            return "achievement_title_control_voiceover"
        case .controlDigitalCrown:
            return "achievement_title_control_crown"
        case .controlGameController:
            return "achievement_title_control_gamecontroller"
        default:
            return nil
        }
    }

    private var localizedControlAchievedDescriptionKey: String? {
        switch self {
        case .controlTap:
            return "achievement_achieved_control_tap"
        case .controlSwipe:
            return "achievement_achieved_control_swipe"
        case .controlKeyboard:
            return "achievement_achieved_control_keyboard"
        case .controlVoiceOver:
            return "achievement_achieved_control_voiceover"
        case .controlDigitalCrown:
            return "achievement_achieved_control_crown"
        case .controlGameController:
            return "achievement_achieved_control_gamecontroller"
        default:
            return nil
        }
    }

    private var totalOvertakesTitleLabel: String? {
        switch self {
        case .totalOvertakes1k:
            return "1K"
        case .totalOvertakes5k:
            return "5K"
        case .totalOvertakes10k:
            return "10K"
        case .totalOvertakes20k:
            return "20K"
        case .totalOvertakes50k:
            return "50K"
        case .totalOvertakes100k:
            return "100K"
        case .totalOvertakes200k:
            return "200K"
        default:
            return nil
        }
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
}
