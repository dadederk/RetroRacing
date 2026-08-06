//
//  GameCenterLeaderboardLocalizationCatalog.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public struct GameCenterLeaderboardLocalizationCatalog: Decodable, Sendable {
    public struct LocalizationCopy: Decodable, Sendable {
        public let name: String
        public let formatterSuffixSingular: String
        public let formatterSuffix: String
    }

    public struct Leaderboard: Decodable, Sendable {
        public let referenceName: String
        public let vendorLeaderboardId: String
        public let platform: String
        public let difficulty: String
        public let templateVendorLeaderboardId: String?
        public let localizations: [String: LocalizationCopy]

        private enum CodingKeys: String, CodingKey {
            case referenceName
            case vendorLeaderboardId
            case platform
            case difficulty
            case templateVendorLeaderboardId
            case localizations
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            referenceName = try container.decode(String.self, forKey: .referenceName)
            vendorLeaderboardId = try container.decode(String.self, forKey: .vendorLeaderboardId)
            platform = try container.decode(String.self, forKey: .platform)
            difficulty = try container.decode(String.self, forKey: .difficulty)
            templateVendorLeaderboardId = try container.decodeIfPresent(
                String.self,
                forKey: .templateVendorLeaderboardId
            )
            localizations = try container.decodeIfPresent(
                [String: LocalizationCopy].self,
                forKey: .localizations
            ) ?? [:]
        }
    }

    public let schemaVersion: Int
    public let appId: String
    public let locales: [String]
    public let leaderboards: [Leaderboard]

    public static func load(from url: URL) throws -> GameCenterLeaderboardLocalizationCatalog {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(
            GameCenterLeaderboardLocalizationCatalog.self,
            from: data
        )
    }

    public func localizationCopy(
        for locale: String,
        leaderboard: Leaderboard
    ) -> LocalizationCopy? {
        if let copy = leaderboard.localizations[locale] {
            return copy
        }
        guard let templateVendorLeaderboardId = leaderboard.templateVendorLeaderboardId,
              let template = leaderboards.first(where: {
                  $0.vendorLeaderboardId == templateVendorLeaderboardId
              }) else {
            return nil
        }
        return template.localizations[locale]
    }
}
