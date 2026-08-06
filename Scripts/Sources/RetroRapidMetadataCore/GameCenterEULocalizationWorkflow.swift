//
//  GameCenterEULocalizationWorkflow.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation
import ScriptSupport

public struct GameCenterEULocalizationApplyOptions: Sendable {
    public let appID: String
    public let achievementsCatalogRelativePath: String
    public let leaderboardsCatalogRelativePath: String
    public let includeAchievements: Bool
    public let includeLeaderboards: Bool
    public let dryRun: Bool
    public let ensureLeaderboards: Bool
    public let sourceImageLocale: String
    public let copyImagesFromSourceLocale: Bool

    public init(
        appID: String,
        achievementsCatalogRelativePath: String,
        leaderboardsCatalogRelativePath: String,
        includeAchievements: Bool,
        includeLeaderboards: Bool,
        dryRun: Bool,
        ensureLeaderboards: Bool = false,
        sourceImageLocale: String = "en-US",
        copyImagesFromSourceLocale: Bool = true
    ) {
        self.appID = appID
        self.achievementsCatalogRelativePath = achievementsCatalogRelativePath
        self.leaderboardsCatalogRelativePath = leaderboardsCatalogRelativePath
        self.includeAchievements = includeAchievements
        self.includeLeaderboards = includeLeaderboards
        self.dryRun = dryRun
        self.ensureLeaderboards = ensureLeaderboards
        self.sourceImageLocale = sourceImageLocale
        self.copyImagesFromSourceLocale = copyImagesFromSourceLocale
    }
}

public enum GameCenterEULocalizationWorkflow {
    public static func check(
        repositoryRoot: URL,
        options: GameCenterEULocalizationApplyOptions
    ) throws {
        var messages: [String] = []

        if options.includeAchievements {
            let catalogURL = repositoryRoot.appending(path: options.achievementsCatalogRelativePath)
            let catalog = try GameCenterAchievementLocalizationCatalog.load(from: catalogURL)
            try validateAchievementCatalog(catalog, expectedAppID: options.appID)
            messages.append(
                "Achievements: \(catalog.achievements.count) entries × \(catalog.locales.count) locales"
            )
        }

        if options.includeLeaderboards {
            let catalogURL = repositoryRoot.appending(path: options.leaderboardsCatalogRelativePath)
            let catalog = try GameCenterLeaderboardLocalizationCatalog.load(from: catalogURL)
            try validateLeaderboardCatalog(catalog, expectedAppID: options.appID)
            messages.append(
                "Leaderboards: \(catalog.leaderboards.count) entries × \(catalog.locales.count) locales"
            )
        }

        for message in messages {
            print(message)
        }
        print("Game Center EU localization catalogs are valid.")
    }

    public static func apply(
        repositoryRoot: URL,
        options: GameCenterEULocalizationApplyOptions
    ) throws {
        guard let credentials = AppStoreConnectCredentialsLoader.load() else {
            throw MetadataToolError.invalidArguments(
                AppStoreConnectCredentialsLoader.missingCredentialsMessage()
            )
        }

        var messages: [String] = []

        if options.includeAchievements {
            let catalogURL = repositoryRoot.appending(path: options.achievementsCatalogRelativePath)
            let catalog = try GameCenterAchievementLocalizationCatalog.load(from: catalogURL)
            guard catalog.appId == options.appID else {
                throw MetadataToolError.invalidArguments(
                    "Achievement catalog appId \(catalog.appId) does not match \(options.appID)."
                )
            }
            fputs("Applying Game Center achievement localizations…\n", stderr)
            let achievementMessages = try awaitResult {
                try await AppStoreConnectGameCenterClient.upsertAchievementLocalizations(
                    appID: options.appID,
                    catalog: catalog,
                    credentials: credentials,
                    dryRun: options.dryRun,
                    sourceImageLocale: options.sourceImageLocale,
                    copyImagesFromSourceLocale: options.copyImagesFromSourceLocale
                )
            }
            messages += achievementMessages
        }

        if options.includeLeaderboards {
            let catalogURL = repositoryRoot.appending(path: options.leaderboardsCatalogRelativePath)
            let catalog = try GameCenterLeaderboardLocalizationCatalog.load(from: catalogURL)
            guard catalog.appId == options.appID else {
                throw MetadataToolError.invalidArguments(
                    "Leaderboard catalog appId \(catalog.appId) does not match \(options.appID)."
                )
            }
            fputs("Applying Game Center leaderboard localizations…\n", stderr)
            let leaderboardMessages = try awaitResult {
                try await AppStoreConnectGameCenterClient.upsertLeaderboardLocalizations(
                    appID: options.appID,
                    catalog: catalog,
                    credentials: credentials,
                    dryRun: options.dryRun,
                    ensureMissingLeaderboards: options.ensureLeaderboards,
                    sourceImageLocale: options.sourceImageLocale,
                    copyImagesFromSourceLocale: options.copyImagesFromSourceLocale
                )
            }
            messages += leaderboardMessages
        }

        if messages.isEmpty {
            print("No Game Center localizations were planned.")
        }

        if options.dryRun {
            print("Dry run complete — no App Store Connect changes were written.")
            print("Run without --dry-run to apply leaderboards, text updates, and image copies.")
        }
    }

    private static func awaitResult<T: Sendable>(
        _ operation: @Sendable @escaping () async throws -> T
    ) throws -> T {
        let semaphore = DispatchSemaphore(value: 0)
        let box = ResultBox<T>()
        Task {
            do {
                box.result = .success(try await operation())
            } catch {
                box.result = .failure(error)
            }
            semaphore.signal()
        }
        semaphore.wait()
        return try box.result.get()
    }

    private static func validateAchievementCatalog(
        _ catalog: GameCenterAchievementLocalizationCatalog,
        expectedAppID: String
    ) throws {
        guard catalog.appId == expectedAppID else {
            throw MetadataToolError.invalidArguments(
                "Achievement catalog appId \(catalog.appId) does not match \(expectedAppID)."
            )
        }
        var vendorIDs = Set<String>()
        for achievement in catalog.achievements {
            guard achievement.vendorId.isEmpty == false else {
                throw MetadataToolError.validationFailed([
                    "Achievement \(achievement.referenceName) has an empty vendorId.",
                ])
            }
            guard vendorIDs.insert(achievement.vendorId).inserted else {
                throw MetadataToolError.validationFailed([
                    "Duplicate achievement vendorId: \(achievement.vendorId).",
                ])
            }
            for locale in catalog.locales {
                guard let copy = achievement.localizations[locale] else {
                    throw MetadataToolError.missingCopy(
                        field: "achievement localization",
                        locale: "\(achievement.referenceName)/\(locale)"
                    )
                }
                guard copy.name.isEmpty == false,
                      copy.preEarnedDescription.isEmpty == false,
                      copy.earnedDescription.isEmpty == false else {
                    throw MetadataToolError.validationFailed([
                        "Achievement \(achievement.referenceName) has empty copy for \(locale).",
                    ])
                }
            }
        }
    }

    private static func validateLeaderboardCatalog(
        _ catalog: GameCenterLeaderboardLocalizationCatalog,
        expectedAppID: String
    ) throws {
        guard catalog.appId == expectedAppID else {
            throw MetadataToolError.invalidArguments(
                "Leaderboard catalog appId \(catalog.appId) does not match \(expectedAppID)."
            )
        }
        var vendorIDs = Set<String>()
        for leaderboard in catalog.leaderboards {
            guard leaderboard.vendorLeaderboardId.isEmpty == false else {
                throw MetadataToolError.validationFailed([
                    "Leaderboard \(leaderboard.referenceName) has an empty vendorLeaderboardId.",
                ])
            }
            guard vendorIDs.insert(leaderboard.vendorLeaderboardId).inserted else {
                throw MetadataToolError.validationFailed([
                    "Duplicate leaderboard vendorLeaderboardId: \(leaderboard.vendorLeaderboardId).",
                ])
            }
            if let templateVendorLeaderboardId = leaderboard.templateVendorLeaderboardId {
                guard templateVendorLeaderboardId != leaderboard.vendorLeaderboardId else {
                    throw MetadataToolError.validationFailed([
                        "Leaderboard \(leaderboard.referenceName) cannot template itself.",
                    ])
                }
                guard catalog.leaderboards.contains(where: {
                    $0.vendorLeaderboardId == templateVendorLeaderboardId
                        && $0.difficulty == leaderboard.difficulty
                }) else {
                    throw MetadataToolError.validationFailed([
                        "Leaderboard \(leaderboard.referenceName) has no same-difficulty template " +
                            "for vendor ID \(templateVendorLeaderboardId).",
                    ])
                }
            }
            for locale in catalog.locales {
                guard let copy = catalog.localizationCopy(for: locale, leaderboard: leaderboard) else {
                    throw MetadataToolError.missingCopy(
                        field: "leaderboard localization",
                        locale: "\(leaderboard.referenceName)/\(locale)"
                    )
                }
                guard copy.name.isEmpty == false,
                      copy.formatterSuffixSingular.isEmpty == false,
                      copy.formatterSuffix.isEmpty == false else {
                    throw MetadataToolError.validationFailed([
                        "Leaderboard \(leaderboard.referenceName) has empty copy for \(locale).",
                    ])
                }
            }
        }
    }
}

private final class ResultBox<T: Sendable>: @unchecked Sendable {
    var result: Result<T, Error> = .failure(
        MetadataToolError.appStoreConnectFailed("App Store Connect API task did not finish.")
    )
}
