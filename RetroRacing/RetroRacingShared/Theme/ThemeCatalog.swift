//
//  ThemeCatalog.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 02/08/2026.
//

import Foundation

public extension ThemePlatformConfig {
    static var iPhone: ThemePlatformConfig {
        configuration(defaultThemeID: .lcd, freeThemeIDs: [.lcd])
    }

    static var iPad: ThemePlatformConfig {
        configuration(defaultThemeID: .eightBit, freeThemeIDs: [.eightBit])
    }

    static var macOS: ThemePlatformConfig {
        configuration(defaultThemeID: .sixteenBit, freeThemeIDs: [.sixteenBit])
    }

    static var tvOS: ThemePlatformConfig {
        configuration(defaultThemeID: .sixteenBit, freeThemeIDs: [.sixteenBit])
    }

    static var watchOS: ThemePlatformConfig {
        configuration(
            defaultThemeID: .pocket,
            freeThemeIDs: Set(orderedThemeIDs)
        )
    }

    static func screenshotCapture(platform: String?) -> ThemePlatformConfig {
        switch platform?.lowercased() {
        case "ipad":
            .iPad
        case "mac", "macos":
            .macOS
        case "watch", "applewatch":
            .watchOS
        case "tv", "tvos":
            .tvOS
        default:
            .iPhone
        }
    }

    private static let orderedThemeIDs: [ThemeID] = [
        .pocket,
        .lcd,
        .eightBit,
        .sixteenBit,
    ]

    private static func configuration(
        defaultThemeID: ThemeID,
        freeThemeIDs: Set<ThemeID>
    ) -> ThemePlatformConfig {
        let themes = orderedThemeIDs.map { id in
            makeTheme(id: id, isPremium: freeThemeIDs.contains(id) == false)
        }
        return ThemePlatformConfig(
            defaultTheme: makeTheme(id: defaultThemeID, isPremium: false),
            availableThemes: themes
        )
    }

    private static func makeTheme(id: ThemeID, isPremium: Bool) -> any GameTheme {
        switch id {
        case .pocket:
            PocketTheme(isPremium: isPremium)
        case .lcd:
            LCDTheme(isPremium: isPremium)
        case .eightBit:
            EightBitTheme(isPremium: isPremium)
        case .sixteenBit:
            SixteenBitTheme(isPremium: isPremium)
        default:
            LCDTheme(isPremium: isPremium)
        }
    }
}
