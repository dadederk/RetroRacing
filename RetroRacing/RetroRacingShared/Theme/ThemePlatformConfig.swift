//
//  ThemePlatformConfig.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation

public enum ThemeCatalogPlatform: Equatable, Sendable {
    case custom
    case iPhone
    case iPad
    case macOS
    case watchOS
    case tvOS
    case visionOS

    public func alwaysIncludes(_ themeID: ThemeID) -> Bool {
        switch (self, themeID) {
        case (.tvOS, .thirtyTwoBit), (.visionOS, .sixtyFourBit):
            true
        default:
            false
        }
    }

    public func showsExperimentalToggle(for themeID: ThemeID) -> Bool {
        self != .custom && alwaysIncludes(themeID) == false
    }
}

public struct ExperimentalThemeConfiguration: Equatable, Sendable {
    public let isThirtyTwoBitEnabled: Bool
    public let isSixtyFourBitEnabled: Bool

    public init(
        isThirtyTwoBitEnabled: Bool,
        isSixtyFourBitEnabled: Bool
    ) {
        self.isThirtyTwoBitEnabled = isThirtyTwoBitEnabled
        self.isSixtyFourBitEnabled = isSixtyFourBitEnabled
    }

    public static let disabled = ExperimentalThemeConfiguration(
        isThirtyTwoBitEnabled: false,
        isSixtyFourBitEnabled: false
    )

    public func contains(_ themeID: ThemeID) -> Bool {
        switch themeID {
        case .thirtyTwoBit:
            isThirtyTwoBitEnabled
        case .sixtyFourBit:
            isSixtyFourBitEnabled
        default:
            false
        }
    }
}

public struct ThemePlatformConfig {
    public let platform: ThemeCatalogPlatform
    public let defaultTheme: any GameTheme
    public let availableThemes: [any GameTheme]

    public var defaultThemeID: ThemeID { defaultTheme.id }

    public init(
        platform: ThemeCatalogPlatform = .custom,
        defaultTheme: any GameTheme,
        availableThemes: [any GameTheme]
    ) {
        var seenIDs: Set<ThemeID> = []
        var uniqueThemes = availableThemes.filter { seenIDs.insert($0.id).inserted }
        if seenIDs.insert(defaultTheme.id).inserted {
            uniqueThemes.append(defaultTheme)
        }

        self.platform = platform
        self.defaultTheme = uniqueThemes.first(where: { $0.id == defaultTheme.id })
            ?? defaultTheme
        self.availableThemes = uniqueThemes
    }
}
