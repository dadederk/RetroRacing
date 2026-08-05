//
//  LocalizationReviewCollector.swift
//  RetroRacing
//
//  Created by Dani Devesa on 05/08/2026.
//

import Foundation
import RetroRapidMetadataCore
import ScriptSupport

public enum LocalizationReviewCollector {
    public static let manifestRelativePath = "AppStore/localization/review-status.json"
    public static let catalogRelativePath = "RetroRacing/RetroRacingShared/Localizable.xcstrings"
    public static let metadataRelativePath = "AppStore/metadata/retrorapid-v1.6.json"
    public static let achievementRelativePath = "AppStore/game-center/achievements-eu-localizations.json"
    public static let leaderboardRelativePath = "AppStore/game-center/leaderboards-eu-localizations.json"
    public static let iapRelativePath = "AppStore/iap-localizations/6759012658"
    public static let testFlightRelativePath = "AppStore/testflight/beta-notes"

    public static func snapshots(
        repositoryRoot: URL,
        selectedLocale: String? = nil
    ) throws -> [LocalizationReviewSnapshot] {
        let manifest = try LocalizationReviewManifest.load(
            from: repositoryRoot.appending(path: manifestRelativePath)
        )
        let localeOrder = ScreenshotStudioWorkflow.locales
        let selected = try resolvedLocales(
            selectedLocale,
            orderedLocales: localeOrder,
            manifest: manifest
        )
        let catalog = try loadStringCatalog(repositoryRoot: repositoryRoot)
        let metadata = try MetadataCatalogLoader.loadCatalog(
            from: repositoryRoot.appending(path: metadataRelativePath)
        )
        let achievements = try GameCenterAchievementLocalizationCatalog.load(
            from: repositoryRoot.appending(path: achievementRelativePath)
        )
        let leaderboards = try GameCenterLeaderboardLocalizationCatalog.load(
            from: repositoryRoot.appending(path: leaderboardRelativePath)
        )

        return try selected.map { locale in
            guard let record = manifest.locales[locale] else {
                throw LocalizationReviewError.missingManifestLocale(locale)
            }
            var items = try catalogItems(
                locale: locale,
                catalogLocale: record.catalogLocale,
                catalog: catalog
            )
            items += try metadataItems(locale: locale, metadata: metadata)
            items += try iapItems(locale: locale, repositoryRoot: repositoryRoot)
            items += try gameCenterItems(
                locale: locale,
                achievements: achievements,
                leaderboards: leaderboards
            )
            items += try screenshotItems(locale: locale)
            items.append(try testFlightItem(locale: locale, repositoryRoot: repositoryRoot))
            return LocalizationReviewSnapshot(
                locale: locale,
                record: record,
                items: items
            )
        }
    }

    private static func resolvedLocales(
        _ requested: String?,
        orderedLocales: [String],
        manifest: LocalizationReviewManifest
    ) throws -> [String] {
        guard let requested else { return orderedLocales }
        if orderedLocales.contains(requested) { return [requested] }
        let matches = orderedLocales.filter {
            manifest.locales[$0]?.catalogLocale == requested
        }
        guard matches.count == 1, let locale = matches.first else {
            throw LocalizationReviewError.unknownLocale(requested)
        }
        return [locale]
    }

    private static func loadStringCatalog(
        repositoryRoot: URL
    ) throws -> [String: Any] {
        let url = repositoryRoot.appending(path: catalogRelativePath)
        guard let value = try JSONSerialization.jsonObject(
            with: Data(contentsOf: url)
        ) as? [String: Any] else {
            throw LocalizationReviewError.invalidCatalog
        }
        return value
    }

    private static func catalogItems(
        locale: String,
        catalogLocale: String,
        catalog: [String: Any]
    ) throws -> [LocalizationReviewItem] {
        guard let strings = catalog["strings"] as? [String: Any] else {
            throw LocalizationReviewError.invalidCatalog
        }
        return try strings.keys.sorted().compactMap { key in
            guard let entry = strings[key] as? [String: Any],
                  let localizations = entry["localizations"] as? [String: Any] else {
                return nil
            }
            let english = stringUnit(in: localizations, locale: "en") ?? key
            let resolvedTranslation = stringUnit(in: localizations, locale: catalogLocale)
                ?? (catalogLocale == "en" ? key : nil)
            guard let translation = resolvedTranslation else {
                if entry["shouldTranslate"] as? Bool == false { return nil }
                throw LocalizationReviewError.missingCatalogValue(
                    locale: catalogLocale,
                    key: key
                )
            }
            let state = stringState(in: localizations, locale: catalogLocale)
                ?? (catalogLocale == "en" ? "source" : "unknown")
            return LocalizationReviewItem(
                layer: "In-app",
                identifier: key,
                english: english,
                translation: translation,
                state: state
            )
        }
    }

    private static func stringUnit(
        in localizations: [String: Any],
        locale: String
    ) -> String? {
        let localization = localizations[locale] as? [String: Any]
        let unit = localization?["stringUnit"] as? [String: Any]
        return unit?["value"] as? String
    }

    private static func stringState(
        in localizations: [String: Any],
        locale: String
    ) -> String? {
        let localization = localizations[locale] as? [String: Any]
        let unit = localization?["stringUnit"] as? [String: Any]
        return unit?["state"] as? String
    }

    private static func metadataItems(
        locale: String,
        metadata: MetadataCatalog
    ) throws -> [LocalizationReviewItem] {
        guard let localized = metadata.locales[locale],
              let english = metadata.locales["en-US"] else {
            throw LocalizationReviewError.missingMetadataLocale(locale)
        }
        let values: [(String, String, String, String)] = [
            ("name", english.name, localized.name, "≤ \(metadata.limits.nameCharacters) characters"),
            ("subtitle", english.subtitle, localized.subtitle, "≤ \(metadata.limits.subtitleCharacters) characters"),
            ("keywords", english.keywords, localized.keywords, "≤ \(metadata.limits.keywordBytes) UTF-8 bytes"),
            ("promotionalText", english.promotionalText, localized.promotionalText, "≤ \(metadata.limits.promotionalTextCharacters) characters"),
            ("description", english.description, localized.description, "≤ \(metadata.limits.descriptionCharacters) characters"),
            ("whatsNew", english.whatsNew, localized.whatsNew, "≤ \(metadata.limits.whatsNewCharacters) characters"),
        ]
        return values.map {
            LocalizationReviewItem(
                layer: "App Store metadata",
                identifier: $0.0,
                english: $0.1,
                translation: $0.2,
                limit: $0.3,
                state: "needs_review"
            )
        }
    }

    private static func iapItems(
        locale: String,
        repositoryRoot: URL
    ) throws -> [LocalizationReviewItem] {
        let englishName = "Unlimited Plays"
        let englishDescription = "Play unlimited and support RetroRapid!"
        if locale == "en-US" || locale.hasPrefix("en-") {
            return [
                LocalizationReviewItem(
                    layer: "IAP",
                    identifier: "unlimitedPlays.name",
                    english: englishName,
                    translation: englishName,
                    limit: "≤ 30 characters",
                    state: locale == "en-US" ? "source" : "inherited"
                ),
                LocalizationReviewItem(
                    layer: "IAP",
                    identifier: "unlimitedPlays.description",
                    english: englishDescription,
                    translation: englishDescription,
                    limit: "≤ 45 characters",
                    state: locale == "en-US" ? "source" : "inherited"
                ),
            ]
        }
        let localizedURL = repositoryRoot
            .appending(path: iapRelativePath)
            .appending(path: locale)
            .appending(path: "metadata.csv")
        let localized = try CSVDictionaryReader.read(url: localizedURL)
        return [
            LocalizationReviewItem(
                layer: "IAP",
                identifier: "unlimitedPlays.name",
                english: englishName,
                translation: localized["name"] ?? "",
                limit: "≤ 30 characters",
                state: "needs_review"
            ),
            LocalizationReviewItem(
                layer: "IAP",
                identifier: "unlimitedPlays.description",
                english: englishDescription,
                translation: localized["description"] ?? "",
                limit: "≤ 45 characters",
                state: "needs_review"
            ),
        ]
    }

    private static func gameCenterItems(
        locale: String,
        achievements: GameCenterAchievementLocalizationCatalog,
        leaderboards: GameCenterLeaderboardLocalizationCatalog
    ) throws -> [LocalizationReviewItem] {
        let usesEnglish = locale == "en-US" || locale.hasPrefix("en-")
        let outputState = locale == "en-US" ? "source" : (usesEnglish ? "inherited" : "needs_review")
        var items: [LocalizationReviewItem] = []
        for achievement in achievements.achievements {
            let english = try englishAchievementCopy(referenceName: achievement.referenceName)
            let copy: GameCenterAchievementLocalizationCatalog.LocalizationCopy
            if usesEnglish {
                copy = english
            } else if let localized = achievement.localizations[locale] {
                copy = localized
            } else {
                throw LocalizationReviewError.missingGameCenterCopy(
                    locale: locale,
                    identifier: achievement.vendorId
                )
            }
            let prefix = "achievement.\(achievement.vendorId)"
            items += [
                LocalizationReviewItem(layer: "Game Center", identifier: "\(prefix).name", english: english.name, translation: copy.name, limit: "≤ 100 characters", state: outputState),
                LocalizationReviewItem(layer: "Game Center", identifier: "\(prefix).preEarnedDescription", english: english.preEarnedDescription, translation: copy.preEarnedDescription, limit: "≤ 200 characters", state: outputState),
                LocalizationReviewItem(layer: "Game Center", identifier: "\(prefix).earnedDescription", english: english.earnedDescription, translation: copy.earnedDescription, limit: "≤ 200 characters", state: outputState),
            ]
        }
        for leaderboard in leaderboards.leaderboards {
            let englishName = GameCenterLeaderboardDisplayNameBuilder.displayName(
                platform: leaderboard.platform,
                difficulty: leaderboard.difficulty,
                locale: "en-US",
                englishReferenceName: leaderboard.referenceName
            )
            let localizedName = GameCenterLeaderboardDisplayNameBuilder.displayName(
                platform: leaderboard.platform,
                difficulty: leaderboard.difficulty,
                locale: usesEnglish ? "en-US" : locale,
                englishReferenceName: leaderboard.referenceName
            )
            let englishDescription = GameCenterLeaderboardDescriptionBuilder.defaultDescription(
                for: "en-US"
            )
            let localizedDescription = GameCenterLeaderboardDescriptionBuilder.defaultDescription(
                for: usesEnglish ? "en-US" : locale
            )
            let copy: GameCenterLeaderboardLocalizationCatalog.LocalizationCopy?
            if usesEnglish {
                copy = nil
            } else if let localized = leaderboard.localizations[locale] {
                copy = localized
            } else {
                throw LocalizationReviewError.missingGameCenterCopy(
                    locale: locale,
                    identifier: leaderboard.vendorLeaderboardId
                )
            }
            let prefix = "leaderboard.\(leaderboard.vendorLeaderboardId)"
            items += [
                LocalizationReviewItem(layer: "Game Center", identifier: "\(prefix).displayName", english: englishName, translation: localizedName, limit: "≤ 30 characters", state: outputState),
                LocalizationReviewItem(layer: "Game Center", identifier: "\(prefix).description", english: englishDescription, translation: localizedDescription, limit: "≤ 500 characters", state: outputState),
                LocalizationReviewItem(layer: "Game Center", identifier: "\(prefix).difficulty", english: leaderboard.difficulty.capitalized, translation: copy?.name ?? leaderboard.difficulty.capitalized, limit: "", state: outputState),
                LocalizationReviewItem(layer: "Game Center", identifier: "\(prefix).suffixSingular", english: "overtake", translation: copy?.formatterSuffixSingular ?? "overtake", limit: "", state: outputState),
                LocalizationReviewItem(layer: "Game Center", identifier: "\(prefix).suffixPlural", english: "overtakes", translation: copy?.formatterSuffix ?? "overtakes", limit: "", state: outputState),
            ]
        }
        return items
    }

    private static func englishAchievementCopy(
        referenceName: String
    ) throws -> GameCenterAchievementLocalizationCatalog.LocalizationCopy {
        if let count = numericSuffix(in: referenceName, prefix: "runOvertakes") {
            return .init(
                name: "Streak \(count)",
                earnedDescription: "You overtook \(count) cars in one run.",
                preEarnedDescription: "Overtake \(count) cars in one run."
            )
        }
        if let label = stringSuffix(in: referenceName, prefix: "totalOvertakes") {
            let displayLabel = label.uppercased()
            let achievementCount = [
                "1K": "1,000",
                "5K": "5,000",
                "10K": "10,000",
                "20K": "20,000",
                "50K": "50,000",
                "100K": "100,000",
                "200K": "200,000",
            ][displayLabel] ?? displayLabel
            return .init(
                name: "Overlander \(displayLabel)",
                earnedDescription: "You overtook \(achievementCount) cars in total.",
                preEarnedDescription: "Overtake \(achievementCount) cars in total."
            )
        }
        let controlNames = [
            "controlTap": "Tap",
            "controlSwipe": "Swipe",
            "controlKeyboard": "Keyboard",
            "controlVoiceOver": "VoiceOver",
            "controlDigitalCrown": "Digital Crown",
            "controlGameController": "Game Controller",
        ]
        if let controlName = controlNames[referenceName] {
            return .init(
                name: "\(controlName) Controls",
                earnedDescription: "You completed a run using \(controlName) controls.",
                preEarnedDescription: "Complete a run using \(controlName) controls."
            )
        }
        if referenceName == "eventGAADAssistive" {
            return .init(
                name: "GAAD Assistive Week",
                earnedDescription: "You completed a run during GAAD week using assistive technology.",
                preEarnedDescription: "Complete a run during GAAD week using assistive technology."
            )
        }
        throw LocalizationReviewError.missingEnglishGameCenterCopy(referenceName)
    }

    private static func numericSuffix(in value: String, prefix: String) -> Int? {
        guard value.hasPrefix(prefix) else { return nil }
        return Int(value.dropFirst(prefix.count))
    }

    private static func stringSuffix(in value: String, prefix: String) -> String? {
        guard value.hasPrefix(prefix) else { return nil }
        let suffix = String(value.dropFirst(prefix.count))
        return suffix.isEmpty ? nil : suffix
    }

    private static func screenshotItems(locale: String) throws -> [LocalizationReviewItem] {
        var items: [LocalizationReviewItem] = []
        for index in 0..<ScreenshotStudioWorkflow.slideCount {
            let entries = try ScreenshotStudioWorkflow.localizationEntries(
                slideIndex: index,
                watchSequenceOnly: false
            )
            guard let english = entries.first(where: { $0["language"] == "en-US" }),
                  let localized = entries.first(where: { $0["language"] == locale }) else {
                throw LocalizationReviewError.missingScreenshotCopy(locale)
            }
            items += [
                LocalizationReviewItem(layer: "Screenshots", identifier: "slide.\(index).title", english: english["title"] ?? "", translation: localized["title"] ?? "", state: "needs_review"),
                LocalizationReviewItem(layer: "Screenshots", identifier: "slide.\(index).body", english: english["body"] ?? "", translation: localized["body"] ?? "", state: "needs_review"),
            ]
        }
        return items
    }

    private static func testFlightItem(
        locale: String,
        repositoryRoot: URL
    ) throws -> LocalizationReviewItem {
        let root = repositoryRoot.appending(path: testFlightRelativePath)
        let english = try String(
            contentsOf: root.appending(path: "en-US/whats-new.txt"),
            encoding: .utf8
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        let localized = try String(
            contentsOf: root.appending(path: "\(locale)/whats-new.txt"),
            encoding: .utf8
        ).trimmingCharacters(in: .whitespacesAndNewlines)
        return LocalizationReviewItem(
            layer: "TestFlight",
            identifier: "whats-new",
            english: english,
            translation: localized,
            limit: "≤ 4,000 characters",
            state: "needs_review"
        )
    }
}

public enum LocalizationReviewError: LocalizedError {
    case invalidCatalog
    case missingManifestLocale(String)
    case missingCatalogValue(locale: String, key: String)
    case missingMetadataLocale(String)
    case missingGameCenterCopy(locale: String, identifier: String)
    case missingEnglishGameCenterCopy(String)
    case missingScreenshotCopy(String)
    case unknownLocale(String)
    case auditFailed([String])
    case generatedFilesOutOfDate([String])

    public var errorDescription: String? {
        switch self {
        case .invalidCatalog:
            "Localizable.xcstrings is not a valid String Catalog."
        case let .missingManifestLocale(locale):
            "review-status.json is missing \(locale)."
        case let .missingCatalogValue(locale, key):
            "String Catalog is missing \(locale) for \(key)."
        case let .missingMetadataLocale(locale):
            "Metadata catalog is missing \(locale)."
        case let .missingGameCenterCopy(locale, identifier):
            "Game Center catalog is missing \(locale) for \(identifier)."
        case let .missingEnglishGameCenterCopy(identifier):
            "No English Game Center source copy is defined for \(identifier)."
        case let .missingScreenshotCopy(locale):
            "Screenshot copy is missing \(locale)."
        case let .unknownLocale(locale):
            "Unknown localization review locale: \(locale)."
        case let .auditFailed(errors):
            (["Localization audit failed:"] + errors.map { "- \($0)" }).joined(separator: "\n")
        case let .generatedFilesOutOfDate(paths):
            (["Localization review files are out of date:"] + paths.map { "- \($0)" }).joined(separator: "\n")
        }
    }
}
