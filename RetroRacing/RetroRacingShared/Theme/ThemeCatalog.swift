//
//  ThemeCatalog.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 02/08/2026.
//

import Foundation

public extension ThemePlatformConfig {
    static var iPhone: ThemePlatformConfig {
        configuration(for: .iPhone)
    }

    static var iPad: ThemePlatformConfig {
        configuration(for: .iPad)
    }

    static var macOS: ThemePlatformConfig {
        configuration(for: .macOS)
    }

    static var tvOS: ThemePlatformConfig {
        configuration(for: .tvOS)
    }

    static var visionOS: ThemePlatformConfig {
        configuration(for: .visionOS)
    }

    static var watchOS: ThemePlatformConfig {
        configuration(for: .watchOS)
    }

    static func configuration(
        for platform: ThemeCatalogPlatform,
        experimentalThemes: ExperimentalThemeConfiguration = .disabled
    ) -> ThemePlatformConfig {
        let platformPolicy = policy(for: platform)
        let enabledExperimentalIDs = experimentalThemeIDs.filter {
            platform.alwaysIncludes($0) || experimentalThemes.contains($0)
        }
        let baseThemeIDs = platform == .visionOS ? [] : orderedThemeIDs
        return configuration(
            platform: platform,
            defaultThemeID: platformPolicy.defaultThemeID,
            freeThemeIDs: platformPolicy.freeThemeIDs.union(enabledExperimentalIDs),
            themeIDs: baseThemeIDs + enabledExperimentalIDs
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

    private static let experimentalThemeIDs: [ThemeID] = [
        .thirtyTwoBit,
        .sixtyFourBit,
    ]

    private static func policy(
        for platform: ThemeCatalogPlatform
    ) -> (defaultThemeID: ThemeID, freeThemeIDs: Set<ThemeID>) {
        switch platform {
        case .iPhone, .custom:
            (.lcd, [.lcd])
        case .iPad:
            (.eightBit, [.eightBit])
        case .macOS:
            (.sixteenBit, [.sixteenBit])
        case .watchOS:
            (.pocket, Set(orderedThemeIDs))
        case .tvOS:
            (.thirtyTwoBit, [.thirtyTwoBit])
        case .visionOS:
            (.sixtyFourBit, [.sixtyFourBit])
        }
    }

    private static func configuration(
        platform: ThemeCatalogPlatform,
        defaultThemeID: ThemeID,
        freeThemeIDs: Set<ThemeID>,
        themeIDs: [ThemeID] = orderedThemeIDs
    ) -> ThemePlatformConfig {
        let themes = themeIDs.map { id in
            makeTheme(id: id, isPremium: freeThemeIDs.contains(id) == false)
        }
        return ThemePlatformConfig(
            platform: platform,
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
        case .thirtyTwoBit:
            ThirtyTwoBitTheme(isPremium: isPremium)
        case .sixtyFourBit:
            SixtyFourBitTheme(isPremium: isPremium)
        default:
            LCDTheme(isPremium: isPremium)
        }
    }
}
