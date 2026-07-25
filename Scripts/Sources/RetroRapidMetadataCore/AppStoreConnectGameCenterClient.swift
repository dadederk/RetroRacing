//
//  AppStoreConnectGameCenterClient.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public enum AppStoreConnectGameCenterClient {
    private static func logProgress(_ message: String, to messages: inout [String]) {
        messages.append(message)
        print(message)
    }

    public static func upsertAchievementLocalizations(
        appID: String,
        catalog: GameCenterAchievementLocalizationCatalog,
        credentials: AppStoreConnectCredentials,
        dryRun: Bool,
        sourceImageLocale: String = "en-US",
        copyImagesFromSourceLocale: Bool = true
    ) async throws -> [String] {
        let token = try AppStoreConnectJWT.makeToken(credentials: credentials)
        let detailID = try await fetchGameCenterDetailID(appID: appID, token: token)
        let achievementsByVendorID = try await fetchAchievementsByVendorID(
            detailID: detailID,
            token: token
        )

        var messages: [String] = []
        for achievement in catalog.achievements {
            guard let achievementID = achievementsByVendorID[achievement.vendorId] else {
                throw MetadataToolError.invalidArguments(
                    "Missing Game Center achievement in ASC for vendor ID \(achievement.vendorId) " +
                        "(\(achievement.referenceName))."
                )
            }

            var existingByLocale = try await fetchAchievementLocalizationIDsByLocale(
                achievementID: achievementID,
                token: token
            )

            for locale in catalog.locales {
                guard let copy = achievement.localizations[locale] else { continue }
                let localizationID: String
                if let existingID = existingByLocale[locale] {
                    if dryRun {
                        logProgress(
                            "[dry-run] PATCH achievement \(achievement.referenceName) \(locale)",
                            to: &messages
                        )
                        localizationID = existingID
                    } else {
                        try await patchAchievementLocalization(
                            id: existingID,
                            copy: copy,
                            token: token
                        )
                        logProgress(
                            "Updated achievement \(achievement.referenceName) [\(locale)].",
                            to: &messages
                        )
                        localizationID = existingID
                    }
                } else {
                    if dryRun {
                        logProgress(
                            "[dry-run] CREATE achievement \(achievement.referenceName) \(locale)",
                            to: &messages
                        )
                        localizationID = ""
                    } else {
                        localizationID = try await createAchievementLocalization(
                            achievementID: achievementID,
                            locale: locale,
                            copy: copy,
                            token: token
                        )
                        logProgress(
                            "Created achievement \(achievement.referenceName) [\(locale)].",
                            to: &messages
                        )
                        existingByLocale[locale] = localizationID
                    }
                }

                if copyImagesFromSourceLocale,
                   locale != sourceImageLocale,
                   dryRun || localizationID.isEmpty == false {
                    if let imageMessage = try await AppStoreConnectGameCenterImageClient.copyImageFromSourceLocaleIfNeeded(
                        kind: .achievement,
                        parentID: achievementID,
                        targetLocalizationID: localizationID,
                        localizationIDsByLocale: existingByLocale,
                        sourceLocale: sourceImageLocale,
                        referenceLabel: achievement.referenceName,
                        targetLocale: locale,
                        token: token,
                        dryRun: dryRun
                    ) {
                        logProgress(imageMessage, to: &messages)
                    }
                }
            }
        }
        return messages
    }

    public static func upsertLeaderboardLocalizations(
        appID: String,
        catalog: GameCenterLeaderboardLocalizationCatalog,
        credentials: AppStoreConnectCredentials,
        dryRun: Bool,
        sourceImageLocale: String = "en-US",
        copyImagesFromSourceLocale: Bool = true
    ) async throws -> [String] {
        let token = try AppStoreConnectJWT.makeToken(credentials: credentials)
        let detailID = try await fetchGameCenterDetailID(appID: appID, token: token)
        let leaderboardsByVendorID = try await fetchLeaderboardsByVendorID(
            detailID: detailID,
            token: token
        )

        var messages: [String] = []
        for leaderboard in catalog.leaderboards {
            guard let leaderboardID = leaderboardsByVendorID[leaderboard.vendorLeaderboardId] else {
                throw MetadataToolError.invalidArguments(
                    "Missing Game Center leaderboard in ASC for vendor ID " +
                        "\(leaderboard.vendorLeaderboardId) (\(leaderboard.referenceName))."
                )
            }

            var existingByLocale = try await fetchLeaderboardLocalizationIDsByLocale(
                leaderboardID: leaderboardID,
                token: token
            )
            let metadataByLocale = try await fetchLeaderboardLocalizationMetadataByLocale(
                leaderboardID: leaderboardID,
                token: token
            )
            let englishReferenceName = metadataByLocale[sourceImageLocale]?.name
            let englishReferenceDescription = metadataByLocale[sourceImageLocale]?.description

            for locale in catalog.locales {
                guard let copy = leaderboard.localizations[locale] else { continue }
                let resolvedCopy = LeaderboardLocalizationPayload(
                    name: GameCenterLeaderboardDisplayNameBuilder.displayName(
                        platform: leaderboard.platform,
                        difficulty: leaderboard.difficulty,
                        locale: locale,
                        englishReferenceName: englishReferenceName
                    ),
                    description: GameCenterLeaderboardDescriptionBuilder.description(
                        locale: locale,
                        englishReferenceDescription: englishReferenceDescription
                    ),
                    formatterSuffixSingular: copy.formatterSuffixSingular,
                    formatterSuffix: copy.formatterSuffix
                )
                let localizationID: String
                if let existingID = existingByLocale[locale] {
                    if dryRun {
                        logProgress(
                            "[dry-run] PATCH leaderboard \(leaderboard.referenceName) \(locale)",
                            to: &messages
                        )
                        localizationID = existingID
                    } else {
                        try await patchLeaderboardLocalization(
                            id: existingID,
                            copy: resolvedCopy,
                            token: token
                        )
                        logProgress(
                            "Updated leaderboard \(leaderboard.referenceName) [\(locale)].",
                            to: &messages
                        )
                        localizationID = existingID
                    }
                } else {
                    if dryRun {
                        logProgress(
                            "[dry-run] CREATE leaderboard \(leaderboard.referenceName) \(locale)",
                            to: &messages
                        )
                        localizationID = ""
                    } else {
                        localizationID = try await createLeaderboardLocalization(
                            leaderboardID: leaderboardID,
                            locale: locale,
                            copy: resolvedCopy,
                            token: token
                        )
                        logProgress(
                            "Created leaderboard \(leaderboard.referenceName) [\(locale)].",
                            to: &messages
                        )
                        existingByLocale[locale] = localizationID
                    }
                }

                if copyImagesFromSourceLocale,
                   locale != sourceImageLocale,
                   dryRun || localizationID.isEmpty == false {
                    if let imageMessage = try await AppStoreConnectGameCenterImageClient.copyImageFromSourceLocaleIfNeeded(
                        kind: .leaderboard,
                        parentID: leaderboardID,
                        targetLocalizationID: localizationID,
                        localizationIDsByLocale: existingByLocale,
                        sourceLocale: sourceImageLocale,
                        referenceLabel: leaderboard.referenceName,
                        targetLocale: locale,
                        token: token,
                        dryRun: dryRun
                    ) {
                        logProgress(imageMessage, to: &messages)
                    }
                }
            }
        }
        return messages
    }

    private static func fetchGameCenterDetailID(
        appID: String,
        token: String
    ) async throws -> String {
        let url = AppStoreConnectHTTPClient.v1BaseURL
            .appending(path: "apps/\(appID)/gameCenterDetail")
        let json = try await AppStoreConnectHTTPClient.get(url: url, token: token)
        guard let detailID = AppStoreConnectHTTPClient.resourceID(from: json) else {
            throw MetadataToolError.appStoreConnectFailed(
                "App Store Connect did not return a gameCenterDetail ID for app \(appID)."
            )
        }
        return detailID
    }

    private static func fetchAchievementsByVendorID(
        detailID: String,
        token: String
    ) async throws -> [String: String] {
        var components = URLComponents(
            url: AppStoreConnectHTTPClient.v1BaseURL.appending(
                path: "gameCenterDetails/\(detailID)/gameCenterAchievements"
            ),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "limit", value: "200"),
            URLQueryItem(
                name: "fields[gameCenterAchievements]",
                value: "vendorIdentifier"
            ),
        ]
        guard let url = components?.url else {
            throw MetadataToolError.appStoreConnectFailed("Could not build gameCenterAchievements URL.")
        }

        let json = try await AppStoreConnectHTTPClient.get(url: url, token: token)
        var byVendorID: [String: String] = [:]
        for row in AppStoreConnectHTTPClient.resourceRows(from: json) {
            guard let id = row["id"] as? String,
                  let vendorID = AppStoreConnectHTTPClient.stringAttribute(
                    named: "vendorIdentifier",
                    in: row
                  ) else {
                continue
            }
            byVendorID[vendorID] = id
        }
        return byVendorID
    }

    private static func fetchLeaderboardsByVendorID(
        detailID: String,
        token: String
    ) async throws -> [String: String] {
        var components = URLComponents(
            url: AppStoreConnectHTTPClient.v1BaseURL.appending(
                path: "gameCenterDetails/\(detailID)/gameCenterLeaderboards"
            ),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "limit", value: "200"),
            URLQueryItem(
                name: "fields[gameCenterLeaderboards]",
                value: "vendorIdentifier"
            ),
        ]
        guard let url = components?.url else {
            throw MetadataToolError.appStoreConnectFailed("Could not build gameCenterLeaderboards URL.")
        }

        let json = try await AppStoreConnectHTTPClient.get(url: url, token: token)
        var byVendorID: [String: String] = [:]
        for row in AppStoreConnectHTTPClient.resourceRows(from: json) {
            guard let id = row["id"] as? String,
                  let vendorID = AppStoreConnectHTTPClient.stringAttribute(
                    named: "vendorIdentifier",
                    in: row
                  ) else {
                continue
            }
            byVendorID[vendorID] = id
        }
        return byVendorID
    }

    private static func fetchAchievementLocalizationIDsByLocale(
        achievementID: String,
        token: String
    ) async throws -> [String: String] {
        var components = URLComponents(
            url: AppStoreConnectHTTPClient.v1BaseURL.appending(
                path: "gameCenterAchievements/\(achievementID)/localizations"
            ),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "limit", value: "200")]
        guard let url = components?.url else {
            throw MetadataToolError.appStoreConnectFailed("Could not build achievement localizations URL.")
        }

        let json = try await AppStoreConnectHTTPClient.get(url: url, token: token)
        return localizationIDsByLocale(from: json)
    }

    private struct LeaderboardLocalizationMetadata: Sendable {
        let name: String
        let description: String?
    }

    private struct LeaderboardLocalizationPayload: Sendable {
        let name: String
        let description: String
        let formatterSuffixSingular: String
        let formatterSuffix: String
    }

    private static func fetchLeaderboardLocalizationMetadataByLocale(
        leaderboardID: String,
        token: String
    ) async throws -> [String: LeaderboardLocalizationMetadata] {
        var components = URLComponents(
            url: AppStoreConnectHTTPClient.v1BaseURL.appending(
                path: "gameCenterLeaderboards/\(leaderboardID)/localizations"
            ),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "limit", value: "200"),
            URLQueryItem(
                name: "fields[gameCenterLeaderboardLocalizations]",
                value: "locale,name,description"
            ),
        ]
        guard let url = components?.url else {
            throw MetadataToolError.appStoreConnectFailed("Could not build leaderboard localizations URL.")
        }

        let json = try await AppStoreConnectHTTPClient.get(url: url, token: token)
        var byLocale: [String: LeaderboardLocalizationMetadata] = [:]
        for row in AppStoreConnectHTTPClient.resourceRows(from: json) {
            guard let locale = AppStoreConnectHTTPClient.stringAttribute(named: "locale", in: row),
                  let name = AppStoreConnectHTTPClient.stringAttribute(named: "name", in: row) else {
                continue
            }
            let description = AppStoreConnectHTTPClient.stringAttribute(
                named: "description",
                in: row
            )
            byLocale[locale] = LeaderboardLocalizationMetadata(
                name: name,
                description: description
            )
        }
        return byLocale
    }

    private static func fetchLeaderboardLocalizationIDsByLocale(
        leaderboardID: String,
        token: String
    ) async throws -> [String: String] {
        var components = URLComponents(
            url: AppStoreConnectHTTPClient.v1BaseURL.appending(
                path: "gameCenterLeaderboards/\(leaderboardID)/localizations"
            ),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "limit", value: "200")]
        guard let url = components?.url else {
            throw MetadataToolError.appStoreConnectFailed("Could not build leaderboard localizations URL.")
        }

        let json = try await AppStoreConnectHTTPClient.get(url: url, token: token)
        return localizationIDsByLocale(from: json)
    }

    static func localizationIDsByLocale(from json: [String: Any]) -> [String: String] {
        var byLocale: [String: String] = [:]
        for row in AppStoreConnectHTTPClient.resourceRows(from: json) {
            guard let id = row["id"] as? String,
                  let locale = AppStoreConnectHTTPClient.stringAttribute(named: "locale", in: row) else {
                continue
            }
            byLocale[locale] = id
        }
        return byLocale
    }

    private static func createAchievementLocalization(
        achievementID: String,
        locale: String,
        copy: GameCenterAchievementLocalizationCatalog.LocalizationCopy,
        token: String
    ) async throws -> String {
        let body: [String: Any] = [
            "data": [
                "type": "gameCenterAchievementLocalizations",
                "attributes": [
                    "locale": locale,
                    "name": copy.name,
                    "beforeEarnedDescription": copy.preEarnedDescription,
                    "afterEarnedDescription": copy.earnedDescription,
                ],
                "relationships": [
                    "gameCenterAchievement": [
                        "data": [
                            "type": "gameCenterAchievements",
                            "id": achievementID,
                        ],
                    ],
                ],
            ],
        ]
        let json = try await AppStoreConnectHTTPClient.post(
            path: "gameCenterAchievementLocalizations",
            body: body,
            token: token
        )
        guard let localizationID = AppStoreConnectHTTPClient.resourceID(from: json) else {
            throw MetadataToolError.appStoreConnectFailed(
                "App Store Connect did not return an achievement localization ID."
            )
        }
        return localizationID
    }

    private static func patchAchievementLocalization(
        id: String,
        copy: GameCenterAchievementLocalizationCatalog.LocalizationCopy,
        token: String
    ) async throws {
        let body: [String: Any] = [
            "data": [
                "type": "gameCenterAchievementLocalizations",
                "id": id,
                "attributes": [
                    "name": copy.name,
                    "beforeEarnedDescription": copy.preEarnedDescription,
                    "afterEarnedDescription": copy.earnedDescription,
                ],
            ],
        ]
        _ = try await AppStoreConnectHTTPClient.patch(
            path: "gameCenterAchievementLocalizations/\(id)",
            body: body,
            token: token
        )
    }

    private static func createLeaderboardLocalization(
        leaderboardID: String,
        locale: String,
        copy: LeaderboardLocalizationPayload,
        token: String
    ) async throws -> String {
        let body: [String: Any] = [
            "data": [
                "type": "gameCenterLeaderboardLocalizations",
                "attributes": leaderboardLocalizationAttributes(from: copy, locale: locale),
                "relationships": [
                    "gameCenterLeaderboard": [
                        "data": [
                            "type": "gameCenterLeaderboards",
                            "id": leaderboardID,
                        ],
                    ],
                ],
            ],
        ]
        let json = try await AppStoreConnectHTTPClient.post(
            path: "gameCenterLeaderboardLocalizations",
            body: body,
            token: token
        )
        guard let localizationID = AppStoreConnectHTTPClient.resourceID(from: json) else {
            throw MetadataToolError.appStoreConnectFailed(
                "App Store Connect did not return a leaderboard localization ID."
            )
        }
        return localizationID
    }

    private static func patchLeaderboardLocalization(
        id: String,
        copy: LeaderboardLocalizationPayload,
        token: String
    ) async throws {
        let body: [String: Any] = [
            "data": [
                "type": "gameCenterLeaderboardLocalizations",
                "id": id,
                "attributes": leaderboardLocalizationAttributes(from: copy),
            ],
        ]
        do {
            _ = try await AppStoreConnectHTTPClient.patch(
                path: "gameCenterLeaderboardLocalizations/\(id)",
                body: body,
                token: token
            )
        } catch MetadataToolError.appStoreConnectFailed(let message) where message.contains("HTTP 422") {
            _ = try await AppStoreConnectHTTPClient.patch(
                path: "gameCenterLeaderboardLocalizations/\(id)",
                body: body,
                token: token,
                baseURL: AppStoreConnectHTTPClient.v2BaseURL
            )
        }
    }

    private static func leaderboardLocalizationAttributes(
        from copy: LeaderboardLocalizationPayload,
        locale: String? = nil
    ) -> [String: Any] {
        var attributes: [String: Any] = [
            "name": copy.name,
            "description": copy.description,
            "formatterOverride": "INTEGER",
            "formatterSuffixSingular": copy.formatterSuffixSingular,
            "formatterSuffix": copy.formatterSuffix,
        ]
        if let locale {
            attributes["locale"] = locale
        }
        return attributes
    }
}
