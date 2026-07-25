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
        public let localizations: [String: LocalizationCopy]
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
}
