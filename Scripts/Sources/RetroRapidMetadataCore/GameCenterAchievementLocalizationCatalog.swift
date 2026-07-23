//
//  GameCenterAchievementLocalizationCatalog.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

public struct GameCenterAchievementLocalizationCatalog: Decodable, Sendable {
    public struct LocalizationCopy: Decodable, Sendable {
        public let name: String
        public let earnedDescription: String
        public let preEarnedDescription: String
    }

    public struct Achievement: Decodable, Sendable {
        public let referenceName: String
        public let vendorId: String
        public let localizations: [String: LocalizationCopy]
    }

    public let schemaVersion: Int
    public let appId: String
    public let locales: [String]
    public let achievements: [Achievement]

    public static func load(from url: URL) throws -> GameCenterAchievementLocalizationCatalog {
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(
            GameCenterAchievementLocalizationCatalog.self,
            from: data
        )
    }

    public func renderedChecklist() -> String {
        var lines: [String] = []
        lines.append(
            "App \(appId) — \(achievements.count) achievements × \(locales.count) locales"
        )
        lines.append("")
        lines.append(
            "Helm CLI: no public gameCenterAchievement upload route in current helm-asc build."
        )
        lines.append(
            "Use App Store Connect UI or asc CLI (see AppStore/game-center/README.md)."
        )
        lines.append("")

        for achievement in achievements {
            lines.append("## \(achievement.referenceName) (\(achievement.vendorId))")
            for locale in locales {
                guard let copy = achievement.localizations[locale] else { continue }
                lines.append("  [\(locale)] name: \(copy.name)")
                lines.append("           pre:  \(copy.preEarnedDescription)")
                lines.append("           post: \(copy.earnedDescription)")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }
}
