//
//  AppIconCatalog.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import Foundation

/// One selectable app icon and its permanent system compatibility name.
public struct AppIconOption: Identifiable, Hashable, Sendable {
    public let id: AppIconID
    public let group: AppIconGroup
    public let nameKey: String
    public let accessibilityDescriptionKey: String
    public let previewAssetName: String
    public let darkPreviewAssetName: String?
    public let systemIconName: String?

    public var localizedName: String {
        GameLocalizedStrings.string(nameKey)
    }

    public var localizedAccessibilityDescription: String {
        GameLocalizedStrings.string(accessibilityDescriptionKey)
    }
}

/// Canonical ordering and system-name mapping for the app icon gallery.
public enum AppIconCatalog {
    public static let options: [AppIconOption] = [
        option(.classic, group: .classic, systemIconName: nil),
        option(.pocket, group: .themes, systemIconName: "RetroRapidPocket"),
        option(.lcd, group: .themes, systemIconName: "RetroRapidLCD"),
        option(.cartridge, group: .themes, systemIconName: "RetroRapidCartridge"),
        option(.crt, group: .themes, systemIconName: "RetroRapidCRT"),
        option(.disc, group: .themes, systemIconName: "RetroRapidDisc"),
        option(.polygon, group: .themes, systemIconName: "RetroRapidPolygon"),
        option(.retroCartridge, group: .specialEditions, systemIconName: "RetroRapidGameCartridge"),
        option(.retroVideoGame, group: .specialEditions, systemIconName: "RetroRapidVideoGame"),
    ]

    public static func options(in group: AppIconGroup) -> [AppIconOption] {
        options.filter { $0.group == group }
    }

    public static func option(for id: AppIconID) -> AppIconOption? {
        options.first { $0.id == id }
    }

    public static func option(forSystemIconName systemIconName: String?) -> AppIconOption? {
        guard let systemIconName else {
            return option(for: .classic)
        }
        return options.first { $0.systemIconName == systemIconName }
    }

    public static var alternateSystemIconNames: [String] {
        options.compactMap(\.systemIconName)
    }

    private static func option(
        _ id: AppIconID,
        group: AppIconGroup,
        systemIconName: String?
    ) -> AppIconOption {
        let previewAssetName = "AppIconPreview\(previewSuffix(for: id))"
        return AppIconOption(
            id: id,
            group: group,
            nameKey: "app_icon_name_\(id.rawValue)",
            accessibilityDescriptionKey: "app_icon_description_\(id.rawValue)",
            previewAssetName: previewAssetName,
            darkPreviewAssetName: adaptivePreviewIDs.contains(id)
                ? "\(previewAssetName)Dark"
                : nil,
            systemIconName: systemIconName
        )
    }

    private static let adaptivePreviewIDs: Set<AppIconID> = [
        .pocket,
        .lcd,
        .cartridge,
        .crt,
        .disc,
        .retroCartridge,
        .retroVideoGame,
    ]

    private static func previewSuffix(for id: AppIconID) -> String {
        switch id {
        case .classic:
            "Classic"
        case .pocket:
            "Pocket"
        case .lcd:
            "LCD"
        case .cartridge:
            "Cartridge"
        case .crt:
            "CRT"
        case .disc:
            "Disc"
        case .polygon:
            "Polygon"
        case .retroCartridge:
            "RetroCartridge"
        case .retroVideoGame:
            "RetroVideoGame"
        }
    }
}
