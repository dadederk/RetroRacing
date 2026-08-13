//
//  AppIconID.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import Foundation

/// Stable identifiers for the app icon catalog.
public enum AppIconID: String, CaseIterable, Codable, Hashable, Sendable {
    case classic
    case pocket
    case lcd
    case cartridge
    case crt
    case disc
    case polygon
    case retroCartridge
    case retroVideoGame
}

/// User-facing grouping for the app icon gallery.
public enum AppIconGroup: String, CaseIterable, Identifiable, Sendable {
    case classic
    case themes
    case specialEditions

    public var id: Self { self }

    public var localizedTitle: String {
        GameLocalizedStrings.string(localizationKey)
    }

    private var localizationKey: String {
        switch self {
        case .classic:
            "app_icon_group_classic"
        case .themes:
            "app_icon_group_themes"
        case .specialEditions:
            "app_icon_group_special_editions"
        }
    }
}
