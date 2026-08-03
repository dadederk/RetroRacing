//
//  ThemePlatformConfig.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/08/2026.
//

import Foundation

public struct ThemePlatformConfig {
    public let defaultTheme: any GameTheme
    public let availableThemes: [any GameTheme]

    public var defaultThemeID: ThemeID { defaultTheme.id }

    public init(defaultTheme: any GameTheme, availableThemes: [any GameTheme]) {
        var seenIDs: Set<ThemeID> = []
        var uniqueThemes = availableThemes.filter { seenIDs.insert($0.id).inserted }
        if seenIDs.insert(defaultTheme.id).inserted {
            uniqueThemes.append(defaultTheme)
        }

        self.defaultTheme = uniqueThemes.first(where: { $0.id == defaultTheme.id })
            ?? defaultTheme
        self.availableThemes = uniqueThemes
    }
}
