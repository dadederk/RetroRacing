//
//  GameCenterLeaderboardDescriptionBuilder.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

/// Builds Game Center leaderboard descriptions to match en-US ASC copy:
/// a short line explaining that ranking is based on overtakes in one run.
enum GameCenterLeaderboardDescriptionBuilder {
    private static let englishDefaults = [
        "Overtake as many cars as you can in one run.",
        "Overtake as many cars as possible in one run.",
    ]

    static func description(
        locale: String,
        englishReferenceDescription: String?
    ) -> String {
        let trimmedEnglish = englishReferenceDescription?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        if let trimmedEnglish,
           !trimmedEnglish.isEmpty,
           let translated = translation(forEnglish: trimmedEnglish, locale: locale) {
            return translated
        }

        return defaultDescription(for: locale)
    }

    static func defaultDescription(for locale: String) -> String {
        switch locale {
        case "de-DE":
            return "Überhole so viele Autos wie möglich in einem Lauf."
        case "nl-NL":
            return "Haal zoveel mogelijk auto's in in één run."
        case "it":
            return "Supera quante più auto possibile in una singola partita."
        case "fr-FR":
            return "Dépasse autant de voitures que possible en une seule partie."
        case "es-ES":
            return "Adelanta tantos coches como puedas en una sola partida."
        case "ca":
            return "Avança tants cotxes com pugues en una sola partida."
        case "ja":
            return "1ランでできるだけ多くの車を追い抜こう。"
        case "ko":
            return "한 판에서 최대한 많은 차를 추월하세요."
        case "pt-BR":
            return "Ultrapasse o máximo de carros possível em uma corrida."
        case "zh-Hant":
            return "在一局中盡可能超過更多車輛。"
        default:
            return englishDefaults[0]
        }
    }

    private static func translation(forEnglish english: String, locale: String) -> String? {
        let normalizedEnglish = english.lowercased()
        let matchesKnownTemplate = englishDefaults.contains {
            $0.lowercased() == normalizedEnglish
        } || normalizedEnglish.contains("overtake") && normalizedEnglish.contains("one run")

        guard matchesKnownTemplate else {
            return nil
        }

        return defaultDescription(for: locale)
    }
}
