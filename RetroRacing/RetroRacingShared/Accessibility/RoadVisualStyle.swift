//
//  RoadVisualStyle.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 01/03/2026.
//

import Foundation

/// Visual style for road/grid overlays.
public enum RoadVisualStyle: String, CaseIterable, Codable, Sendable {
    case detailedRoad
    case simplifiedGrid

    public static let storageKey = "roadVisualStyle"
    public static let defaultStyle: RoadVisualStyle = .detailedRoad

    public var localizedNameKey: String {
        switch self {
        case .detailedRoad:
            return "settings_road_visual_style_detailed"
        case .simplifiedGrid:
            return "settings_road_visual_style_simplified"
        }
    }

    public static func fromStoredValue(_ value: String?) -> RoadVisualStyle {
        guard let value,
              let style = RoadVisualStyle(rawValue: value) else {
            return defaultStyle
        }
        return style
    }

    public static func currentSelection(from userDefaults: UserDefaults) -> RoadVisualStyle {
        fromStoredValue(userDefaults.string(forKey: storageKey))
    }
}
