import Foundation

/// Shared localizations from RetroRacingShared framework bundle. Use for all game/menu/settings strings so platforms don't duplicate catalogs.
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
