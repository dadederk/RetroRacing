//
//  AppStoreConnectGameCenterImageClient.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

enum AppStoreConnectGameCenterImageKind: Sendable {
    case achievement
    case leaderboard

    var localizationType: String {
        switch self {
        case .achievement:
            "gameCenterAchievementLocalizations"
        case .leaderboard:
            "gameCenterLeaderboardLocalizations"
        }
    }

    var imageType: String {
        switch self {
        case .achievement:
            "gameCenterAchievementImages"
        case .leaderboard:
            "gameCenterLeaderboardImages"
        }
    }

    var imageRelationshipKey: String {
        switch self {
        case .achievement:
            "gameCenterAchievementImage"
        case .leaderboard:
            "gameCenterLeaderboardImage"
        }
    }

    var localizationRelationshipKey: String {
        switch self {
        case .achievement:
            "gameCenterAchievementLocalization"
        case .leaderboard:
            "gameCenterLeaderboardLocalization"
        }
    }

    var parentCollectionPath: String {
        switch self {
        case .achievement:
            "gameCenterAchievements"
        case .leaderboard:
            "gameCenterLeaderboards"
        }
    }
}

enum AppStoreConnectGameCenterImageClient {
    static let defaultSourceLocale = "en-US"

    static func copyImageFromSourceLocaleIfNeeded(
        kind: AppStoreConnectGameCenterImageKind,
        parentID: String,
        targetLocalizationID: String,
        localizationIDsByLocale: [String: String],
        sourceLocale: String,
        referenceLabel: String,
        targetLocale: String,
        token: String,
        dryRun: Bool
    ) async throws -> String? {
        if dryRun == false,
           try await localizationHasImage(
            kind: kind,
            localizationID: targetLocalizationID,
            token: token
           ) {
            return nil
        }

        guard localizationIDsByLocale[sourceLocale] != nil else {
            throw MetadataToolError.invalidArguments(
                "Missing \(sourceLocale) localization to copy \(kind.logLabel) image for \(referenceLabel)."
            )
        }

        guard let sourceAsset = try await fetchSourceImageAsset(
            kind: kind,
            parentID: parentID,
            sourceLocale: sourceLocale,
            token: token
        ) else {
            switch kind {
            case .achievement:
                throw MetadataToolError.invalidArguments(
                    "Missing \(sourceLocale) image to copy for \(referenceLabel). " +
                        "Confirm the en-US localization has an uploaded image in App Store Connect."
                )
            case .leaderboard:
                return nil
            }
        }

        if dryRun {
            return "[dry-run] COPY \(kind.logLabel) image \(sourceLocale) → \(targetLocale) for \(referenceLabel)"
        }

        let imageData = try await AppStoreConnectAssetUpload.downloadAsset(from: sourceAsset.downloadURL)
        let reservation = try await reserveImage(
            kind: kind,
            localizationID: targetLocalizationID,
            fileName: sourceAsset.fileName,
            fileSize: imageData.count,
            token: token
        )
        guard let operation = reservation.uploadOperations.first else {
            throw MetadataToolError.appStoreConnectFailed(
                "App Store Connect did not return upload operations for \(referenceLabel) image."
            )
        }

        try await AppStoreConnectAssetUpload.upload(data: imageData, operation: operation)
        try await AppStoreConnectAssetUpload.commitUploadedGameCenterImage(
            type: kind.imageType,
            id: reservation.imageID,
            token: token
        )

        return "Copied \(kind.logLabel) image from \(sourceLocale) to \(targetLocale) for \(referenceLabel)."
    }

    private struct SourceImageAsset: Sendable {
        let fileName: String
        let downloadURL: URL
    }

    private struct ImageReservation: Sendable {
        let imageID: String
        let uploadOperations: [AppStoreConnectUploadOperation]
    }

    private static func fetchSourceImageAsset(
        kind: AppStoreConnectGameCenterImageKind,
        parentID: String,
        sourceLocale: String,
        token: String
    ) async throws -> SourceImageAsset? {
        if let asset = try await fetchSourceImageAssetFromLocalizationList(
            kind: kind,
            parentID: parentID,
            sourceLocale: sourceLocale,
            token: token
        ) {
            return asset
        }

        guard let sourceLocalizationID = try await fetchLocalizationID(
            kind: kind,
            parentID: parentID,
            locale: sourceLocale,
            token: token
        ) else {
            return nil
        }

        if let asset = try await fetchImageAssetFromRelatedEndpoint(
            kind: kind,
            localizationID: sourceLocalizationID,
            token: token
        ) {
            return asset
        }

        return try await fetchImageAsset(
            kind: kind,
            localizationID: sourceLocalizationID,
            token: token
        )
    }

    private static func fetchImageAssetFromRelatedEndpoint(
        kind: AppStoreConnectGameCenterImageKind,
        localizationID: String,
        token: String
    ) async throws -> SourceImageAsset? {
        var components = URLComponents(
            url: AppStoreConnectHTTPClient.v1BaseURL.appending(
                path: "\(kind.localizationType)/\(localizationID)/\(kind.imageRelationshipKey)"
            ),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(
                name: "fields[\(kind.imageType)]",
                value: "fileName,imageAsset,assetDeliveryState"
            ),
        ]
        guard let url = components?.url else {
            return nil
        }

        do {
            let json = try await AppStoreConnectHTTPClient.get(url: url, token: token)
            guard let resource = AppStoreConnectHTTPClient.singleResource(from: json) else {
                return nil
            }
            return sourceImageAsset(from: resource)
        } catch MetadataToolError.appStoreConnectFailed(let message) where message.contains("HTTP 404") {
            return nil
        }
    }

    private static func fetchSourceImageAssetFromLocalizationList(
        kind: AppStoreConnectGameCenterImageKind,
        parentID: String,
        sourceLocale: String,
        token: String
    ) async throws -> SourceImageAsset? {
        var components = URLComponents(
            url: AppStoreConnectHTTPClient.v1BaseURL.appending(
                path: "\(kind.parentCollectionPath)/\(parentID)/localizations"
            ),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "limit", value: "200"),
            URLQueryItem(name: "include", value: kind.imageRelationshipKey),
            URLQueryItem(
                name: "fields[\(kind.localizationType)]",
                value: "locale"
            ),
            URLQueryItem(
                name: "fields[\(kind.imageType)]",
                value: "fileName,imageAsset,assetDeliveryState"
            ),
        ]
        guard let url = components?.url else {
            return nil
        }

        let json = try await AppStoreConnectHTTPClient.get(url: url, token: token)
        let includedImages = (json["included"] as? [[String: Any]] ?? [])
            .filter { $0["type"] as? String == kind.imageType }

        for row in AppStoreConnectHTTPClient.resourceRows(from: json) {
            guard AppStoreConnectHTTPClient.stringAttribute(named: "locale", in: row) == sourceLocale else {
                continue
            }

            if let imageID = linkedImageID(from: row, kind: kind),
               let asset = sourceImageAsset(from: includedImages.first(where: { $0["id"] as? String == imageID }) ?? [:]) {
                return asset
            }

            if let imageID = linkedImageID(from: row, kind: kind),
               let asset = try await fetchImageAsset(
                kind: kind,
                localizationID: row["id"] as? String ?? "",
                token: token,
                imageIDOverride: imageID
               ) {
                return asset
            }
        }

        return nil
    }

    private static func linkedImageID(
        from localization: [String: Any],
        kind: AppStoreConnectGameCenterImageKind
    ) -> String? {
        guard let relationships = localization["relationships"] as? [String: Any],
              let imageRelationship = relationships[kind.imageRelationshipKey] as? [String: Any],
              let imageData = imageRelationship["data"] as? [String: Any] else {
            return nil
        }
        return imageData["id"] as? String
    }

    private static func fetchLocalizationID(
        kind: AppStoreConnectGameCenterImageKind,
        parentID: String,
        locale: String,
        token: String
    ) async throws -> String? {
        var components = URLComponents(
            url: AppStoreConnectHTTPClient.v1BaseURL.appending(
                path: "\(kind.parentCollectionPath)/\(parentID)/localizations"
            ),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "limit", value: "200"),
            URLQueryItem(
                name: "fields[\(kind.localizationType)]",
                value: "locale"
            ),
        ]
        guard let url = components?.url else {
            return nil
        }

        let json = try await AppStoreConnectHTTPClient.get(url: url, token: token)
        for row in AppStoreConnectHTTPClient.resourceRows(from: json) {
            guard AppStoreConnectHTTPClient.stringAttribute(named: "locale", in: row) == locale,
                  let id = row["id"] as? String else {
                continue
            }
            return id
        }
        return nil
    }

    private static func localizationHasImage(
        kind: AppStoreConnectGameCenterImageKind,
        localizationID: String,
        token: String
    ) async throws -> Bool {
        let json = try await fetchLocalization(
            kind: kind,
            localizationID: localizationID,
            token: token
        )
        return imageResource(from: json, kind: kind) != nil
    }

    private static func fetchImageAsset(
        kind: AppStoreConnectGameCenterImageKind,
        localizationID: String,
        token: String,
        imageIDOverride: String? = nil
    ) async throws -> SourceImageAsset? {
        let imageID: String?
        if let imageIDOverride {
            imageID = imageIDOverride
        } else {
            imageID = try await resolveImageID(
                kind: kind,
                localizationID: localizationID,
                token: token
            )
        }
        guard let imageID else {
            return nil
        }

        var components = URLComponents(
            url: AppStoreConnectHTTPClient.v1BaseURL.appending(path: "\(kind.imageType)/\(imageID)"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(
                name: "fields[\(kind.imageType)]",
                value: "fileName,imageAsset,assetDeliveryState"
            ),
        ]
        guard let imageURL = components?.url else {
            return nil
        }

        let imageJSON = try await AppStoreConnectHTTPClient.get(url: imageURL, token: token)
        guard let resource = AppStoreConnectHTTPClient.singleResource(from: imageJSON) else {
            return nil
        }
        return sourceImageAsset(from: resource)
    }

    private static func sourceImageAsset(from resource: [String: Any]) -> SourceImageAsset? {
        guard let parsed = AppStoreConnectAssetUpload.sourceImageDownload(fromImageResource: resource) else {
            return nil
        }
        return SourceImageAsset(fileName: parsed.fileName, downloadURL: parsed.downloadURL)
    }

    private static func resolveImageID(
        kind: AppStoreConnectGameCenterImageKind,
        localizationID: String,
        token: String
    ) async throws -> String? {
        let json = try await fetchLocalization(
            kind: kind,
            localizationID: localizationID,
            token: token
        )
        if let imageResource = imageResource(from: json, kind: kind),
           let imageID = imageResource["id"] as? String {
            return imageID
        }

        let relatedURL = AppStoreConnectHTTPClient.v1BaseURL.appending(
            path: "\(kind.localizationType)/\(localizationID)/\(kind.imageRelationshipKey)"
        )
        do {
            let relatedJSON = try await AppStoreConnectHTTPClient.get(url: relatedURL, token: token)
            return AppStoreConnectHTTPClient.resourceID(from: relatedJSON)
        } catch {
            return nil
        }
    }

    private static func fetchLocalization(
        kind: AppStoreConnectGameCenterImageKind,
        localizationID: String,
        token: String
    ) async throws -> [String: Any] {
        var components = URLComponents(
            url: AppStoreConnectHTTPClient.v1BaseURL.appending(
                path: "\(kind.localizationType)/\(localizationID)"
            ),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "include", value: kind.imageRelationshipKey),
        ]
        guard let url = components?.url else {
            throw MetadataToolError.appStoreConnectFailed("Could not build Game Center localization URL.")
        }
        return try await AppStoreConnectHTTPClient.get(url: url, token: token)
    }

    private static func imageResource(
        from json: [String: Any],
        kind: AppStoreConnectGameCenterImageKind
    ) -> [String: Any]? {
        if let included = json["included"] as? [[String: Any]] {
            for resource in included where resource["type"] as? String == kind.imageType {
                return resource
            }
        }

        guard let data = AppStoreConnectHTTPClient.singleResource(from: json),
              let relationships = data["relationships"] as? [String: Any],
              let imageRelationship = relationships[kind.imageRelationshipKey] as? [String: Any],
              let imageData = imageRelationship["data"] as? [String: Any],
              let imageID = imageData["id"] as? String else {
            return nil
        }

        return [
            "type": kind.imageType,
            "id": imageID,
        ]
    }

    private static func reserveImage(
        kind: AppStoreConnectGameCenterImageKind,
        localizationID: String,
        fileName: String,
        fileSize: Int,
        token: String
    ) async throws -> ImageReservation {
        let body: [String: Any] = [
            "data": [
                "type": kind.imageType,
                "attributes": [
                    "fileName": fileName,
                    "fileSize": fileSize,
                ],
                "relationships": [
                    kind.localizationRelationshipKey: [
                        "data": [
                            "type": kind.localizationType,
                            "id": localizationID,
                        ],
                    ],
                ],
            ],
        ]
        let json = try await AppStoreConnectHTTPClient.post(
            path: kind.imageType,
            body: body,
            token: token
        )
        guard let resource = AppStoreConnectHTTPClient.singleResource(from: json),
              let imageID = resource["id"] as? String else {
            throw MetadataToolError.appStoreConnectFailed("App Store Connect did not return a reserved image ID.")
        }
        return ImageReservation(
            imageID: imageID,
            uploadOperations: AppStoreConnectAssetUpload.uploadOperations(from: resource)
        )
    }

    private static func intValue(from value: Any?) -> Int? {
        if let intValue = value as? Int {
            return intValue
        }
        if let number = value as? NSNumber {
            return number.intValue
        }
        return nil
    }
}

private extension AppStoreConnectGameCenterImageKind {
    var logLabel: String {
        switch self {
        case .achievement:
            "achievement"
        case .leaderboard:
            "leaderboard"
        }
    }
}
