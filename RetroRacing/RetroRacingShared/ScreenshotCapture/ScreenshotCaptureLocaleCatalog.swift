//
//  ScreenshotCaptureLocaleCatalog.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public enum ScreenshotCaptureLocaleCatalog {
    private static let appleLanguagesKey = "AppleLanguages"
    private static let appleLocaleKey = "AppleLocale"

    public static let appStoreLocales = [
        "en-US", "en-GB", "en-AU", "en-CA",
        "de-DE", "nl-NL", "it", "fr-FR", "fr-CA",
        "es-ES", "es-MX", "ca",
        "ja", "ko", "pt-BR", "pt-PT", "zh-Hant", "zh-Hans",
        "tr", "pl",
    ]

    public static func inAppLanguageIdentifier(for appStoreLocale: String) -> String {
        switch appStoreLocale {
        case "de-DE":
            return "de"
        case "nl-NL":
            return "nl"
        case "fr-FR":
            return "fr"
        case "fr-CA":
            return "fr-CA"
        case "es-ES", "es-MX":
            return "es"
        case "ca":
            return "ca"
        case "en-US":
            return "en"
        case "en-GB":
            return "en-GB"
        case "en-AU":
            return "en-AU"
        case "en-CA":
            return "en-CA"
        case "pt-PT":
            return "pt-PT"
        case "zh-Hans":
            return "zh-Hans"
        default:
            return appStoreLocale
        }
    }

    public static func appleLanguagesArgument(for appStoreLocale: String) -> String {
        "(\(inAppLanguageIdentifier(for: appStoreLocale)))"
    }

    public static func appleLocaleArgument(for appStoreLocale: String) -> String {
        appStoreLocale.replacingOccurrences(of: "-", with: "_")
    }

    /// Locale forced for in-app strings during App Store screenshot capture.
    /// Prefer this over Bundle preferredLocalizations — watchOS often ignores `-AppleLanguages`
    /// for Bundle lookup even when launch arguments are present.
    public static var resolvedCaptureLocale: Locale? {
        guard ScreenshotCaptureConfiguration.isCaptureModeEnabled else { return nil }
        return locale(
            languageList: launchArgumentValue(following: "-AppleLanguages"),
            localeIdentifier: launchArgumentValue(following: "-AppleLocale")
        )
    }

    /// Applies launch-time locale setup for screenshot capture without leaving sticky app defaults.
    public static func configureCaptureLocaleDefaultsForLaunch() {
        removePersistedCaptureLocaleIfNeeded()
        applyCaptureLocaleFromLaunchArgumentsIfNeeded()
    }

    /// Applies `-AppleLanguages` / `-AppleLocale` launch arguments to `UserDefaults` during capture.
    /// watchOS often ignores launch-argument locale unless the simulator language is also set.
    public static func applyCaptureLocaleFromLaunchArgumentsIfNeeded() {
        guard ScreenshotCaptureConfiguration.isCaptureModeEnabled else { return }
        applyCaptureLocale(
            languageList: launchArgumentValue(following: "-AppleLanguages"),
            localeIdentifier: launchArgumentValue(following: "-AppleLocale")
        )
    }

    public static func applyCaptureLocale(languageList: String?, localeIdentifier: String?) {
        applyCaptureLocale(
            languageList: languageList,
            localeIdentifier: localeIdentifier,
            userDefaults: .standard
        )
    }

    static func applyCaptureLocale(
        languageList: String?,
        localeIdentifier: String?,
        userDefaults: UserDefaults
    ) {
        guard let languageList, let localeIdentifier else { return }
        let languages = parseLanguageList(languageList)
        guard languages.isEmpty == false else { return }

        var argumentDomain = userDefaults.volatileDomain(forName: UserDefaults.argumentDomain)
        argumentDomain[appleLanguagesKey] = languages
        argumentDomain[appleLocaleKey] = normalizedLocaleIdentifier(localeIdentifier)
        userDefaults.setVolatileDomain(argumentDomain, forName: UserDefaults.argumentDomain)
    }

    static func removePersistedCaptureLocaleIfNeeded(
        userDefaults: UserDefaults = .standard,
        isCaptureModeEnabled: Bool = ScreenshotCaptureConfiguration.isCaptureModeEnabled,
        hasLaunchLocaleArgument: Bool = launchArgumentValue(following: "-AppleLanguages") != nil
            || launchArgumentValue(following: "-AppleLocale") != nil
    ) {
        guard BuildConfiguration.isDebug else { return }
        guard isCaptureModeEnabled == false else { return }
        guard hasLaunchLocaleArgument == false else { return }

        userDefaults.removeObject(forKey: appleLanguagesKey)
        userDefaults.removeObject(forKey: appleLocaleKey)
    }

    static func locale(languageList: String?, localeIdentifier: String?) -> Locale? {
        guard let languageList else { return nil }
        let languages = parseLanguageList(languageList)
        guard let primaryLanguage = languages.first else { return nil }
        if let localeIdentifier, localeIdentifier.isEmpty == false {
            return Locale(identifier: normalizedLocaleIdentifier(localeIdentifier))
        }
        return Locale(identifier: primaryLanguage)
    }

    static func parseLanguageList(_ raw: String) -> [String] {
        let trimmed = raw.trimmingCharacters(in: CharacterSet(charactersIn: "()"))
        guard trimmed.isEmpty == false else { return [] }
        if trimmed.contains(",") {
            return trimmed
                .split(separator: ",")
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .filter { $0.isEmpty == false }
        }
        return [trimmed]
    }

    static func normalizedLocaleIdentifier(_ raw: String) -> String {
        raw.replacingOccurrences(of: "_", with: "-")
    }

    private static func launchArgumentValue(following flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag), index + 1 < arguments.count else {
            return nil
        }
        return arguments[index + 1]
    }
}
