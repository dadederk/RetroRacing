//
//  GameCenterLeaderboardDisplayNameBuilder.swift
//  RetroRacing
//
//  Created by Dani Devesa on 23/07/2026.
//

import Foundation

/// Builds Game Center leaderboard display names to match in-app speed-level naming:
/// platform prefix + localized "High Score" phrase + untranslated Cruise/Rapid (and localized Fast).
public enum GameCenterLeaderboardDisplayNameBuilder {
    public static let maxDisplayNameLength = 30

    private static let englishHighScorePhrase = "High Score"
    private static let englishSeparator = " - "

    public static func displayName(
        platform: String,
        difficulty: String,
        locale: String,
        englishReferenceName: String?
    ) -> String {
        let levelName = levelName(for: difficulty, locale: locale)
        let platformPrefixes = platformPrefixCandidates(
            platform: platform,
            englishReferenceName: englishReferenceName
        )
        let highScorePhrases = highScorePhraseCandidates(for: locale)

        for platformPrefix in platformPrefixes {
            for highScorePhrase in highScorePhrases {
                let candidate = compose(
                    platformPrefix: platformPrefix,
                    highScorePhrase: highScorePhrase,
                    levelName: levelName
                )
                if candidate.count <= maxDisplayNameLength {
                    return candidate
                }
            }
        }

        let fallbackPrefix = compactPlatformPrefix(
            from: platformPrefixes.first
                ?? platformPrefix(platform: platform, englishReferenceName: englishReferenceName)
        ) ?? platformPrefixes.first ?? platform
        return compose(
            platformPrefix: fallbackPrefix,
            highScorePhrase: shortHighScorePhrase(for: locale),
            levelName: levelName
        )
    }

    static func platformPrefix(
        platform: String,
        englishReferenceName: String?
    ) -> String {
        if let englishReferenceName,
           let range = englishReferenceName.range(of: " \(englishHighScorePhrase)\(englishSeparator)") {
            return String(englishReferenceName[..<range.lowerBound])
        }

        switch platform {
        case "iPhone":
            return "iPhone"
        case "iPad":
            return "iPad"
        case "macOS":
            return "Mac"
        case "watchOS":
            return "Apple Watch"
        case "tvOS":
            return "Apple TV"
        default:
            return platform
        }
    }

    static func highScorePhrase(for locale: String) -> String {
        switch locale {
        case "de-DE":
            return "Bestpunktzahl"
        case "nl-NL":
            return "Highscore"
        case "it":
            return "Miglior punteggio"
        case "fr-FR", "fr-CA":
            return "Meilleur score"
        case "es-ES", "es-MX":
            return "Mejor puntuación"
        case "ca":
            return "Millor puntuació"
        case "ja":
            return "最高スコア"
        case "ko":
            return "최고 점수"
        case "pt-BR", "pt-PT":
            return "Melhor pontuação"
        case "zh-Hant", "zh-Hans":
            return "最高分"
        case "tr":
            return "En Yüksek Skor"
        case "pl":
            return "Najlepszy Wynik"
        default:
            return englishHighScorePhrase
        }
    }

    static func shortHighScorePhrase(for locale: String) -> String {
        switch locale {
        case "de-DE":
            return "Bestscore"
        case "nl-NL":
            return "Highscore"
        case "it", "fr-FR", "fr-CA", "pt-BR", "pt-PT", "es-ES", "es-MX", "ca":
            return "Top score"
        case "ja":
            return "ハイスコア"
        case "ko":
            return "하이스코어"
        case "zh-Hant", "zh-Hans":
            return "高分"
        case "tr":
            return "Rekor"
        case "pl":
            return "Rekord"
        default:
            return englishHighScorePhrase
        }
    }

    static func levelName(for difficulty: String, locale: String) -> String {
        switch difficulty {
        case "cruise":
            return "Cruise"
        case "rapid":
            return "Rapid"
        case "fast":
            switch locale {
            case "de-DE":
                return "Schnell"
            case "nl-NL":
                return "Snel"
            case "it":
                return "Veloce"
            case "fr-FR", "fr-CA":
                return "Rapide"
            case "es-ES", "es-MX":
                return "Rápido"
            case "ca":
                return "Ràpid"
            case "ja":
                return "ファスト"
            case "ko":
                return "패스트"
            case "pt-BR", "pt-PT":
                return "Rápido"
            case "zh-Hant", "zh-Hans":
                return "快速"
            case "tr":
                return "Hızlı"
            case "pl":
                return "Szybki"
            default:
                return "Fast"
            }
        default:
            return difficulty.capitalized
        }
    }

    private static func compose(
        platformPrefix: String,
        highScorePhrase: String,
        levelName: String
    ) -> String {
        "\(platformPrefix) \(highScorePhrase)\(englishSeparator)\(levelName)"
    }

    private static func platformPrefixCandidates(
        platform: String,
        englishReferenceName: String?
    ) -> [String] {
        let primary = platformPrefix(
            platform: platform,
            englishReferenceName: englishReferenceName
        )
        guard let compact = compactPlatformPrefix(from: primary),
              compact != primary else {
            return [primary]
        }
        return [primary, compact]
    }

    private static func compactPlatformPrefix(from prefix: String) -> String? {
        if prefix == "Apple Watch" {
            return "Watch"
        }
        if prefix == "Apple TV" {
            return "TV"
        }
        return nil
    }

    private static func highScorePhraseCandidates(for locale: String) -> [String] {
        let primary = highScorePhrase(for: locale)
        let short = shortHighScorePhrase(for: locale)
        if short == primary {
            return [primary]
        }
        return [primary, short]
    }
}
