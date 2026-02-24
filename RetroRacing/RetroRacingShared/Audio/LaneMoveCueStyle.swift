//
//  LaneMoveCueStyle.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 17/02/2026.
//

import Foundation

/// How move feedback should encode lane changes while cue modes are active.
public enum LaneMoveCueStyle: String, CaseIterable, Codable, Sendable {
    case laneConfirmation
    case safetyOnly
    case laneConfirmationAndSafety
    case haptics

    public static let storageKey = "laneMoveCueStyle"
    public static let defaultStyle: LaneMoveCueStyle = .laneConfirmation

    public var localizedNameKey: String {
        switch self {
        case .laneConfirmation:
            return "settings_lane_move_cue_style_lane_confirmation"
        case .safetyOnly:
            return "settings_lane_move_cue_style_safety_only"
        case .laneConfirmationAndSafety:
            return "settings_lane_move_cue_style_lane_and_safety"
        case .haptics:
            return "settings_lane_move_cue_style_haptics"
        }
    }

    public static func availableStyles(supportsHaptics: Bool) -> [LaneMoveCueStyle] {
        if supportsHaptics {
            return allCases
        }
        return allCases.filter { $0 != .haptics }
    }

    public static func tutorialStyles(supportsHaptics: Bool) -> [LaneMoveCueStyle] {
        availableStyles(supportsHaptics: supportsHaptics)
    }

    public static func fromStoredValue(_ value: String?) -> LaneMoveCueStyle {
        guard let value,
              let style = LaneMoveCueStyle(rawValue: value) else {
            return defaultStyle
        }
        return style
    }

    public static func currentSelection(from userDefaults: UserDefaults) -> LaneMoveCueStyle {
        let selectedStyle = fromStoredValue(userDefaults.string(forKey: storageKey))
        #if os(macOS) || os(tvOS)
        return selectedStyle == .haptics ? .defaultStyle : selectedStyle
        #else
        return selectedStyle
        #endif
    }
}
