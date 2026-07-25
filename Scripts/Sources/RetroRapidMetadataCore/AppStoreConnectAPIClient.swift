//
//  AppStoreConnectAPIClient.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public struct IAPPurchaseLocalizationCopy: Sendable, Equatable {
    public let locale: String
    public let name: String
    public let description: String

    public init(locale: String, name: String, description: String) {
        self.locale = locale
        self.name = name
        self.description = description
    }
}

public enum AppStoreConnectAPIClient {
    private static let v1BaseURL = AppStoreConnectAPIEndpoints.v1BaseURL
    private static let v2BaseURL = AppStoreConnectAPIEndpoints.v2BaseURL

    public static func upsertInAppPurchaseLocalizations(
        iapID: String,
        localizations: [IAPPurchaseLocalizationCopy],
        credentials: AppStoreConnectCredentials,
        dryRun: Bool
    ) async throws -> [String] {
        let token = try AppStoreConnectJWT.makeToken(credentials: credentials)
        let existingByLocale = try await fetchLocalizationIDsByLocale(
            iapID: iapID,
            token: token
        )
        let draftVersionID = try await resolveDraftVersionID(
            iapID: iapID,
            token: token,
            dryRun: dryRun
        )

        var messages: [String] = []
        for localization in localizations {
            if let existingID = existingByLocale[localization.locale] {
                if dryRun {
                    messages.append("[dry-run] PATCH \(localization.locale) (\(existingID))")
                    continue
                }
                try await patchLocalization(
                    id: existingID,
                    copy: localization,
                    token: token
                )
                messages.append("Updated \(localization.locale).")
            } else {
                if dryRun {
                    messages.append(
                        "[dry-run] CREATE \(localization.locale) on version \(draftVersionID)"
                    )
                    continue
                }
                try await createLocalization(
                    versionID: draftVersionID,
                    copy: localization,
                    token: token
                )
                messages.append("Created \(localization.locale).")
            }
        }
        return messages
    }

    static func localizationResourceIDs(from linkageJSON: [String: Any]) -> [String] {
        let rows = linkageJSON["data"] as? [[String: Any]] ?? []
        return rows.compactMap { row in
            guard row["type"] as? String == "inAppPurchaseLocalizations" else {
                return nil
            }
            return row["id"] as? String
        }
    }

    static func localeByLocalizationID(from localizationJSON: [String: Any]) -> (id: String, locale: String)? {
        guard let data = localizationJSON["data"] as? [String: Any],
              let id = data["id"] as? String,
              let attributes = data["attributes"] as? [String: Any],
              let locale = attributes["locale"] as? String else {
            return nil
        }
        return (id, locale)
    }

    static func draftVersionID(from versionsJSON: [String: Any]) -> String? {
        let rows = versionsJSON["data"] as? [[String: Any]] ?? []
        for row in rows {
            guard row["type"] as? String == "inAppPurchaseVersions",
                  let id = row["id"] as? String,
                  let attributes = row["attributes"] as? [String: Any],
                  let state = attributes["state"] as? String,
                  state == "PREPARE_FOR_SUBMISSION" else {
                continue
            }
            return id
        }
        return nil
    }

    static func createdResourceID(from createJSON: [String: Any]) -> String? {
        guard let data = createJSON["data"] as? [String: Any] else {
            return nil
        }
        return data["id"] as? String
    }

    private static func fetchLocalizationIDsByLocale(
        iapID: String,
        token: String
    ) async throws -> [String: String] {
        var components = URLComponents(
            url: v2BaseURL.appending(
                path: "inAppPurchases/\(iapID)/relationships/inAppPurchaseLocalizations"
            ),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "limit", value: "200")]
        guard let url = components?.url else {
            throw MetadataToolError.appStoreConnectFailed("Could not build localization relationship URL.")
        }

        let linkageData = try await send(request: URLRequest(url: url), token: token)
        let linkageJSON = try decodeJSONObject(linkageData)
        let localizationIDs = localizationResourceIDs(from: linkageJSON)

        var byLocale: [String: String] = [:]
        for localizationID in localizationIDs {
            let detailURL = v1BaseURL.appending(path: "inAppPurchaseLocalizations/\(localizationID)")
            let detailData = try await send(request: URLRequest(url: detailURL), token: token)
            let detailJSON = try decodeJSONObject(detailData)
            if let pair = localeByLocalizationID(from: detailJSON) {
                byLocale[pair.locale] = pair.id
            }
        }
        return byLocale
    }

    private static func resolveDraftVersionID(
        iapID: String,
        token: String,
        dryRun: Bool
    ) async throws -> String {
        var components = URLComponents(
            url: v2BaseURL.appending(path: "inAppPurchases/\(iapID)/versions"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [URLQueryItem(name: "limit", value: "50")]
        guard let url = components?.url else {
            throw MetadataToolError.appStoreConnectFailed("Could not build in-app purchase versions URL.")
        }

        let versionsData = try await send(request: URLRequest(url: url), token: token)
        let versionsJSON = try decodeJSONObject(versionsData)
        if let existingDraftVersionID = draftVersionID(from: versionsJSON) {
            return existingDraftVersionID
        }

        if dryRun {
            return "draft-version-placeholder"
        }

        let body: [String: Any] = [
            "data": [
                "type": "inAppPurchaseVersions",
                "relationships": [
                    "inAppPurchase": [
                        "data": [
                            "type": "inAppPurchases",
                            "id": iapID,
                        ],
                    ],
                ],
            ],
        ]
        var request = URLRequest(url: v1BaseURL.appending(path: "inAppPurchaseVersions"))
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let createData = try await send(request: request, token: token)
        let createJSON = try decodeJSONObject(createData)
        guard let versionID = createdResourceID(from: createJSON) else {
            throw MetadataToolError.appStoreConnectFailed(
                "App Store Connect did not return a draft in-app purchase version ID."
            )
        }
        return versionID
    }

    private static func createLocalization(
        versionID: String,
        copy: IAPPurchaseLocalizationCopy,
        token: String
    ) async throws {
        let body: [String: Any] = [
            "data": [
                "type": "inAppPurchaseLocalizations",
                "attributes": [
                    "locale": copy.locale,
                    "name": copy.name,
                    "description": copy.description,
                ],
                "relationships": [
                    "version": [
                        "data": [
                            "type": "inAppPurchaseVersions",
                            "id": versionID,
                        ],
                    ],
                ],
            ],
        ]
        var request = URLRequest(
            url: v2BaseURL.appending(path: "inAppPurchaseLocalizations")
        )
        request.httpMethod = "POST"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        _ = try await send(request: request, token: token)
    }

    private static func patchLocalization(
        id: String,
        copy: IAPPurchaseLocalizationCopy,
        token: String
    ) async throws {
        let body: [String: Any] = [
            "data": [
                "type": "inAppPurchaseLocalizations",
                "id": id,
                "attributes": [
                    "name": copy.name,
                    "description": copy.description,
                ],
            ],
        ]
        var request = URLRequest(
            url: v1BaseURL.appending(path: "inAppPurchaseLocalizations/\(id)")
        )
        request.httpMethod = "PATCH"
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        _ = try await send(request: request, token: token)
    }

    private static func decodeJSONObject(_ data: Data) throws -> [String: Any] {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw MetadataToolError.appStoreConnectFailed("App Store Connect API returned invalid JSON.")
        }
        return json
    }

    private static func send(request: URLRequest, token: String) async throws -> Data {
        var authorizedRequest = request
        authorizedRequest.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: authorizedRequest)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw MetadataToolError.appStoreConnectFailed("App Store Connect API returned a non-HTTP response.")
        }
        guard (200 ... 299).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw MetadataToolError.appStoreConnectFailed(
                "App Store Connect API HTTP \(httpResponse.statusCode): \(body)"
            )
        }
        return data
    }
}
