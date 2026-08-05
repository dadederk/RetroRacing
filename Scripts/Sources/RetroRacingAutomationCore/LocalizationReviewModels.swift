//
//  LocalizationReviewModels.swift
//  RetroRacing
//
//  Created by Dani Devesa on 05/08/2026.
//

import CryptoKit
import Foundation

public enum LocalizationReviewStatus: String, Codable, Sendable {
    case needsReview = "NEEDS_REVIEW"
    case approved = "APPROVED"
}

public struct LocalizationReviewRecord: Codable, Equatable, Sendable {
    public let catalogLocale: String
    public let guidance: String
    public let status: LocalizationReviewStatus
    public let reviewer: String?
    public let reviewedAt: String?
    public let notes: String?
    public let approvedContentDigest: String?
}

public struct LocalizationReviewManifest: Codable, Equatable, Sendable {
    public let schemaVersion: Int
    public let locales: [String: LocalizationReviewRecord]

    public static func load(from url: URL) throws -> Self {
        try JSONDecoder().decode(Self.self, from: Data(contentsOf: url))
    }
}

public struct LocalizationReviewItem: Equatable, Sendable {
    public let layer: String
    public let identifier: String
    public let english: String
    public let translation: String
    public let limit: String
    public let state: String

    public init(
        layer: String,
        identifier: String,
        english: String,
        translation: String,
        limit: String = "",
        state: String
    ) {
        self.layer = layer
        self.identifier = identifier
        self.english = english
        self.translation = translation
        self.limit = limit
        self.state = state
    }
}

public enum LocalizationContentDigest {
    public static func value(for items: [LocalizationReviewItem]) -> String {
        let canonical = items
            .sorted {
                ($0.layer, $0.identifier) < ($1.layer, $1.identifier)
            }
            .map {
                [$0.layer, $0.identifier, $0.english, $0.translation, $0.limit]
                    .joined(separator: "\u{001F}")
            }
            .joined(separator: "\u{001E}")
        let digest = SHA256.hash(data: Data(canonical.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

public struct LocalizationReviewSnapshot: Equatable, Sendable {
    public let locale: String
    public let record: LocalizationReviewRecord
    public let items: [LocalizationReviewItem]

    public var digest: String {
        LocalizationContentDigest.value(for: items)
    }
}
