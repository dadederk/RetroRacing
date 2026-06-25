//
//  MetadataModels.swift
//  RetroRacing
//
//  Created by Dani Devesa on 25/06/2026.
//

import Foundation

public struct MetadataCatalog: Sendable {
    public let sourceURL: URL
    public let version: String
    public let lastUpdated: String
    public let submissionStatus: String
    public let fieldStatuses: [String: String]
    public let limits: MetadataLimits
    public let localeOrder: [String]
    public let locales: [String: LocaleMetadata]
    public let platformDrafts: [String: PlatformDraft]
    public let allowedShortKeywords: Set<String>
    public let screenshotProfiles: [String: Int]

    public var orderedLocales: [LocaleMetadata] {
        localeOrder.compactMap { locales[$0] }
    }
}

public struct MetadataLimits: Codable, Sendable {
    public let nameCharacters: Int
    public let subtitleCharacters: Int
    public let promotionalTextCharacters: Int
    public let descriptionCharacters: Int
    public let keywordBytes: Int
    public let whatsNewCharacters: Int
}

public struct LocaleMetadata: Equatable, Sendable {
    public let code: String
    public let label: String
    public let name: String
    public let subtitle: String
    public let keywords: String
    public let promotionalText: String
    public let description: String
    public let whatsNew: String
}

public struct PlatformDraft: Sendable {
    public let versionID: String
    public let localizationIDs: [String: String]
}

public struct MetadataFieldCounts: Equatable, Sendable {
    public let nameCharacters: Int
    public let subtitleCharacters: Int
    public let promotionalTextCharacters: Int
    public let descriptionCharacters: Int
    public let keywordCharacters: Int
    public let keywordBytes: Int
    public let whatsNewCharacters: Int
}
