//
//  AppStoreConnectGameCenterClient.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public enum AppStoreConnectGameCenterClient {
    private struct LeaderboardConfiguration: Equatable, Sendable {
        let defaultFormatter: String
        let submissionType: String
        let scoreSortType: String
        let scoreRangeStart: String?
        let scoreRangeEnd: String?
    }

    private struct LeaderboardResource: Sendable {
        let id: String
        let referenceName: String
        let vendorIdentifier: String
        let configuration: LeaderboardConfiguration
    }

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
        ensureMissingLeaderboards: Bool = false,
        sourceImageLocale: String = "en-US",
        copyImagesFromSourceLocale: Bool = true
    ) async throws -> [String] {
        let token = try AppStoreConnectJWT.makeToken(credentials: credentials)
        let detailID = try await fetchGameCenterDetailID(appID: appID, token: token)
        var leaderboardsByVendorID = try await fetchLeaderboardResourcesByVendorID(
            detailID: detailID,
            token: token
        )
        var releasedLeaderboardIDs = ensureMissingLeaderboards
            ? try await fetchReleasedLeaderboardIDs(detailID: detailID, token: token)
            : []

        var messages: [String] = []
        let leaderboards = selectedLeaderboards(
            in: catalog,
            ensureMissingLeaderboards: ensureMissingLeaderboards
        )
        for leaderboard in leaderboards {
            let templateResource = leaderboard.templateVendorLeaderboardId.flatMap {
                leaderboardsByVendorID[$0]
            }
            if let templateVendorLeaderboardId = leaderboard.templateVendorLeaderboardId,
               templateResource == nil {
                throw MetadataToolError.invalidArguments(
                    "Missing Game Center template leaderboard in ASC for vendor ID " +
                        "\(templateVendorLeaderboardId)."
                )
            }
            let resource: LeaderboardResource
            let isDryRunCreation: Bool
            if let existingResource = leaderboardsByVendorID[leaderboard.vendorLeaderboardId] {
                if templateResource != nil {
                    try validateExistingLeaderboard(
                        existingResource,
                        expectedReferenceName: leaderboard.referenceName,
                        templateResource: templateResource
                    )
                }
                resource = existingResource
                isDryRunCreation = false
            } else {
                guard ensureMissingLeaderboards,
                      let templateVendorLeaderboardId = leaderboard.templateVendorLeaderboardId,
                      let templateResource else {
                    throw MetadataToolError.invalidArguments(
                        "Missing Game Center leaderboard in ASC for vendor ID " +
                            "\(leaderboard.vendorLeaderboardId) (\(leaderboard.referenceName)). " +
                            "Use --ensure-leaderboards for catalog entries with a template."
                    )
                }
                if dryRun {
                    resource = LeaderboardResource(
                        id: "dry-run-\(leaderboard.vendorLeaderboardId)",
                        referenceName: leaderboard.referenceName,
                        vendorIdentifier: leaderboard.vendorLeaderboardId,
                        configuration: templateResource.configuration
                    )
                    isDryRunCreation = true
                    logProgress(
                        "[dry-run] CREATE leaderboard \(leaderboard.referenceName) " +
                            "from \(templateVendorLeaderboardId)",
                        to: &messages
                    )
                } else {
                    resource = try await createLeaderboard(
                        detailID: detailID,
                        leaderboard: leaderboard,
                        template: templateResource,
                        token: token
                    )
                    isDryRunCreation = false
                    leaderboardsByVendorID[leaderboard.vendorLeaderboardId] = resource
                    logProgress(
                        "Created leaderboard \(leaderboard.referenceName).",
                        to: &messages
                    )
                }
            }

            var existingByLocale = isDryRunCreation
                ? [:]
                : try await fetchLeaderboardLocalizationIDsByLocale(
                    leaderboardID: resource.id,
                    token: token
                )
            var metadataByLocale = isDryRunCreation
                ? [:]
                : try await fetchLeaderboardLocalizationMetadataByLocale(
                    leaderboardID: resource.id,
                    token: token
                )
            let templateMetadataByLocale: [String: LeaderboardLocalizationMetadata]
            if let templateResource {
                templateMetadataByLocale = try await fetchLeaderboardLocalizationMetadataByLocale(
                    leaderboardID: templateResource.id,
                    token: token
                )
            } else {
                templateMetadataByLocale = [:]
            }

            if leaderboard.templateVendorLeaderboardId != nil,
               existingByLocale[sourceImageLocale] == nil {
                let englishCopy = LeaderboardLocalizationPayload(
                    name: GameCenterLeaderboardDisplayNameBuilder.displayName(
                        platform: leaderboard.platform,
                        difficulty: leaderboard.difficulty,
                        locale: sourceImageLocale,
                        englishReferenceName: nil
                    ),
                    description: GameCenterLeaderboardDescriptionBuilder.description(
                        locale: sourceImageLocale,
                        englishReferenceDescription: templateMetadataByLocale[sourceImageLocale]?.description
                    ),
                    formatterSuffixSingular: "car",
                    formatterSuffix: "cars"
                )
                if dryRun {
                    logProgress(
                        "[dry-run] CREATE leaderboard \(leaderboard.referenceName) \(sourceImageLocale)",
                        to: &messages
                    )
                } else {
                    let localizationID = try await createLeaderboardLocalization(
                        leaderboardID: resource.id,
                        locale: sourceImageLocale,
                        copy: englishCopy,
                        token: token
                    )
                    existingByLocale[sourceImageLocale] = localizationID
                    metadataByLocale[sourceImageLocale] = LeaderboardLocalizationMetadata(
                        name: englishCopy.name,
                        description: englishCopy.description
                    )
                    logProgress(
                        "Created leaderboard \(leaderboard.referenceName) [\(sourceImageLocale)].",
                        to: &messages
                    )
                }
            }

            let englishReferenceName = metadataByLocale[sourceImageLocale]?.name
            let englishReferenceDescription = metadataByLocale[sourceImageLocale]?.description
                ?? templateMetadataByLocale[sourceImageLocale]?.description

            for locale in catalog.locales {
                guard let copy = catalog.localizationCopy(for: locale, leaderboard: leaderboard) else {
                    continue
                }
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
                            leaderboardID: resource.id,
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
                   isDryRunCreation == false,
                   locale != sourceImageLocale,
                   dryRun || localizationID.isEmpty == false {
                    if let imageMessage = try await AppStoreConnectGameCenterImageClient.copyImageFromSourceLocaleIfNeeded(
                        kind: .leaderboard,
                        parentID: resource.id,
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

            if ensureMissingLeaderboards,
               leaderboard.templateVendorLeaderboardId != nil,
               releasedLeaderboardIDs.contains(resource.id) == false {
                if dryRun {
                    logProgress(
                        "[dry-run] RELEASE leaderboard \(leaderboard.referenceName)",
                        to: &messages
                    )
                } else {
                    try await createLeaderboardRelease(
                        detailID: detailID,
                        leaderboardID: resource.id,
                        token: token
                    )
                    releasedLeaderboardIDs.insert(resource.id)
                    logProgress(
                        "Released leaderboard \(leaderboard.referenceName).",
                        to: &messages
                    )
                }
            }
        }
        return messages
    }

    static func selectedLeaderboards(
        in catalog: GameCenterLeaderboardLocalizationCatalog,
        ensureMissingLeaderboards: Bool
    ) -> [GameCenterLeaderboardLocalizationCatalog.Leaderboard] {
        guard ensureMissingLeaderboards else { return catalog.leaderboards }
        return catalog.leaderboards.filter { $0.templateVendorLeaderboardId != nil }
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

    private static func fetchLeaderboardResourcesByVendorID(
        detailID: String,
        token: String
    ) async throws -> [String: LeaderboardResource] {
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
                value: "defaultFormatter,referenceName,vendorIdentifier,submissionType," +
                    "scoreSortType,scoreRangeStart,scoreRangeEnd"
            ),
        ]
        guard let url = components?.url else {
            throw MetadataToolError.appStoreConnectFailed("Could not build gameCenterLeaderboards URL.")
        }

        let json = try await AppStoreConnectHTTPClient.get(url: url, token: token)
        var byVendorID: [String: LeaderboardResource] = [:]
        for row in AppStoreConnectHTTPClient.resourceRows(from: json) {
            guard let id = row["id"] as? String,
                  let vendorID = AppStoreConnectHTTPClient.stringAttribute(
                    named: "vendorIdentifier",
                    in: row
                  ),
                  let referenceName = AppStoreConnectHTTPClient.stringAttribute(
                    named: "referenceName",
                    in: row
                  ),
                  let submissionType = AppStoreConnectHTTPClient.stringAttribute(
                    named: "submissionType",
                    in: row
                  ),
                  let scoreSortType = AppStoreConnectHTTPClient.stringAttribute(
                    named: "scoreSortType",
                    in: row
                  ) else {
                continue
            }
            byVendorID[vendorID] = LeaderboardResource(
                id: id,
                referenceName: referenceName,
                vendorIdentifier: vendorID,
                configuration: LeaderboardConfiguration(
                    defaultFormatter: AppStoreConnectHTTPClient.stringAttribute(
                        named: "defaultFormatter",
                        in: row
                    ) ?? "INTEGER",
                    submissionType: submissionType,
                    scoreSortType: scoreSortType,
                    scoreRangeStart: normalizedNumberAttribute(named: "scoreRangeStart", in: row),
                    scoreRangeEnd: normalizedNumberAttribute(named: "scoreRangeEnd", in: row)
                )
            )
        }
        return byVendorID
    }

    private static func normalizedNumberAttribute(
        named name: String,
        in resource: [String: Any]
    ) -> String? {
        guard let attributes = resource["attributes"] as? [String: Any],
              let value = attributes[name] else {
            return nil
        }
        if let string = value as? String {
            return string
        }
        if let number = value as? NSNumber {
            return number.stringValue
        }
        return nil
    }

    private static func validateExistingLeaderboard(
        _ resource: LeaderboardResource,
        expectedReferenceName: String,
        templateResource: LeaderboardResource?
    ) throws {
        guard resource.referenceName == expectedReferenceName else {
            throw MetadataToolError.validationFailed([
                "Leaderboard \(resource.vendorIdentifier) has reference name " +
                    "'\(resource.referenceName)'; expected '\(expectedReferenceName)'.",
            ])
        }
        guard let templateResource else { return }
        guard resource.configuration == templateResource.configuration else {
            throw MetadataToolError.validationFailed([
                "Leaderboard \(resource.vendorIdentifier) does not match score configuration " +
                    "from template \(templateResource.vendorIdentifier).",
            ])
        }
    }

    private static func createLeaderboard(
        detailID: String,
        leaderboard: GameCenterLeaderboardLocalizationCatalog.Leaderboard,
        template: LeaderboardResource,
        token: String
    ) async throws -> LeaderboardResource {
        var attributes: [String: Any] = [
            "referenceName": leaderboard.referenceName,
            "vendorIdentifier": leaderboard.vendorLeaderboardId,
            "defaultFormatter": template.configuration.defaultFormatter,
            "submissionType": template.configuration.submissionType,
            "scoreSortType": template.configuration.scoreSortType,
        ]
        if let scoreRangeStart = template.configuration.scoreRangeStart {
            attributes["scoreRangeStart"] = scoreRangeStart
        }
        if let scoreRangeEnd = template.configuration.scoreRangeEnd {
            attributes["scoreRangeEnd"] = scoreRangeEnd
        }
        let body: [String: Any] = [
            "data": [
                "type": "gameCenterLeaderboards",
                "attributes": attributes,
                "relationships": [
                    "gameCenterDetail": [
                        "data": [
                            "type": "gameCenterDetails",
                            "id": detailID,
                        ],
                    ],
                ],
            ],
        ]
        let json = try await AppStoreConnectHTTPClient.post(
            path: "gameCenterLeaderboards",
            body: body,
            token: token
        )
        guard let id = AppStoreConnectHTTPClient.resourceID(from: json) else {
            throw MetadataToolError.appStoreConnectFailed(
                "App Store Connect did not return a leaderboard ID for " +
                    "\(leaderboard.referenceName)."
            )
        }
        return LeaderboardResource(
            id: id,
            referenceName: leaderboard.referenceName,
            vendorIdentifier: leaderboard.vendorLeaderboardId,
            configuration: template.configuration
        )
    }

    private static func fetchReleasedLeaderboardIDs(
        detailID: String,
        token: String
    ) async throws -> Set<String> {
        var components = URLComponents(
            url: AppStoreConnectHTTPClient.v1BaseURL.appending(
                path: "gameCenterDetails/\(detailID)/leaderboardReleases"
            ),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "limit", value: "200"),
            URLQueryItem(name: "filter[live]", value: "true"),
            URLQueryItem(name: "include", value: "gameCenterLeaderboard"),
        ]
        guard let url = components?.url else {
            throw MetadataToolError.appStoreConnectFailed(
                "Could not build gameCenter leaderboard releases URL."
            )
        }
        let json = try await AppStoreConnectHTTPClient.get(url: url, token: token)
        return Set(AppStoreConnectHTTPClient.resourceRows(from: json).compactMap { row in
            guard let relationships = row["relationships"] as? [String: Any],
                  let leaderboard = relationships["gameCenterLeaderboard"] as? [String: Any],
                  let data = leaderboard["data"] as? [String: Any] else {
                return nil
            }
            return data["id"] as? String
        })
    }

    private static func createLeaderboardRelease(
        detailID: String,
        leaderboardID: String,
        token: String
    ) async throws {
        let body: [String: Any] = [
            "data": [
                "type": "gameCenterLeaderboardReleases",
                "relationships": [
                    "gameCenterDetail": [
                        "data": [
                            "type": "gameCenterDetails",
                            "id": detailID,
                        ],
                    ],
                    "gameCenterLeaderboard": [
                        "data": [
                            "type": "gameCenterLeaderboards",
                            "id": leaderboardID,
                        ],
                    ],
                ],
            ],
        ]
        _ = try await AppStoreConnectHTTPClient.post(
            path: "gameCenterLeaderboardReleases",
            body: body,
            token: token
        )
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
