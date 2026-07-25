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
    /// During screenshot capture, prefers the launch-argument locale so watchOS (and other
    /// platforms that ignore `-AppleLanguages` for Bundle preferredLocalizations) still render
    /// the correct language.
    public static func string(_ key: String) -> String {
        string(key, preferredLocale: ScreenshotCaptureLocaleCatalog.resolvedCaptureLocale)
    }

    /// Returns localized format string; use with String(format: GameLocalizedStrings.string("score %lld"), value).
    public static func format(_ key: String, _ arguments: CVarArg...) -> String {
        String(format: string(key), arguments: arguments)
    }

    static func string(_ key: String, preferredLocale: Locale?) -> String {
        if let preferredLocale,
           let localizationBundle = localizationBundle(for: preferredLocale) {
            return localizationBundle.localizedString(forKey: key, value: nil, table: nil)
        }
        return String(localized: String.LocalizationValue(stringLiteral: key), bundle: bundle)
    }

    /// Resolves `de.lproj` / `nl.lproj` (etc.) inside the shared framework.
    /// Prefer this over `String(localized:locale:)` — that API often still returns the
    /// process preferred language for framework string catalogs.
    static func localizationBundle(for locale: Locale) -> Bundle? {
        for directory in localizationDirectoryCandidates(for: locale) {
            guard let path = bundle.path(forResource: directory, ofType: "lproj") else {
                continue
            }
            return Bundle(path: path)
        }
        return nil
    }

    static func localizationDirectoryCandidates(for locale: Locale) -> [String] {
        var candidates: [String] = []
        let identifier = locale.identifier
        let dashed = identifier.replacingOccurrences(of: "_", with: "-")
        let underscored = identifier.replacingOccurrences(of: "-", with: "_")

        candidates.append(dashed)
        candidates.append(underscored)
        if let languageCode = locale.language.languageCode?.identifier {
            candidates.append(languageCode)
        }

        var unique: [String] = []
        var seen = Set<String>()
        for candidate in candidates where candidate.isEmpty == false {
            let key = candidate.lowercased()
            guard seen.insert(key).inserted else { continue }
            unique.append(candidate)
        }
        return unique
    }
}
