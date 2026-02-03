//
//  GameLocalizedStrings.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// Shared localization helper sourcing strings from the RetroRacingShared bundle.
public enum GameLocalizedStrings {
    private static var bundle: Bundle { Bundle(for: GameScene.self) }

    /// Returns localized string for key from the shared framework bundle.
    public static func string(_ key: String) -> String {
        String(localized: String.LocalizationValue(stringLiteral: key), bundle: bundle)
    }

    /// Returns localized format string; use with String(format: GameLocalizedStrings.string("score %lld"), value).
    public static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), arguments: arguments)
    }
}
