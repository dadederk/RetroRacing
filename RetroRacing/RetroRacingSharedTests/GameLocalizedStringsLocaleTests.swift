//
//  GameLocalizedStringsLocaleTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 23/07/2026.
//

import XCTest

@testable import RetroRacingShared

final class GameLocalizedStringsLocaleTests: XCTestCase {
    private let checkpointKeys = [
        "play",
        "settings",
        "game_over_encouragement_title",
        "paywall_limit_notice",
        "menu_engagement_prompt",
        "shareplay_activity_title",
    ]

    private let supportedLocales = [
        "de", "nl", "it", "fr", "fr-CA", "es", "es-MX", "ca",
        "ja", "ko", "pt-BR", "pt-PT", "zh-Hant", "zh-Hans",
        "tr", "pl",
    ]

    func testGivenSupportedLocalesWhenResolvingCheckpointKeysThenValuesAreNonEmpty() {
        for localeIdentifier in supportedLocales {
            let locale = Locale(identifier: localeIdentifier)
            for key in checkpointKeys {
                let value = localizedString(key, locale: locale)
                XCTAssertFalse(
                    value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                    "Expected non-empty \(localeIdentifier) value for \(key)"
                )
                XCTAssertNotEqual(
                    value,
                    key,
                    "Expected translated value for \(localeIdentifier) key \(key)"
                )
            }
        }
    }

    func testGivenGermanLocaleWhenResolvingPaywallLimitNoticeThenPitStopToneIsPreserved() {
        let value = localizedString("paywall_limit_notice", locale: Locale(identifier: "de"))
        XCTAssertTrue(value.contains("Boxenstopp") || value.contains("Pit stop"))
    }

    func testGivenFrenchLocaleWhenResolvingGameOverEncouragementThenExclamationIsPreserved() {
        let value = localizedString("game_over_encouragement_title", locale: Locale(identifier: "fr"))
        XCTAssertTrue(value.contains("!"))
    }

    func testGivenFrenchLocaleWhenResolvingPaywallCaptionThenGrammarUsesPluralAgreement() {
        let value = localizedString("paywall_caption_coffee", locale: Locale(identifier: "fr"))
        XCTAssertTrue(value.contains("te plairont"))
        XCTAssertFalse(value.contains("te plaire."))
    }

    func testGivenItalianLocaleWhenResolvingGameOverBestThenRecordTerminologyIsUsed() {
        let value = localizedString("game_over_your_best %lld", locale: Locale(identifier: "it"))
        XCTAssertTrue(value.contains("record"))
        XCTAssertFalse(value.contains("migliore"))
    }

    func testGivenItalianLocaleWhenResolvingAchievementModalThenObiettiviTerminologyIsUsed() {
        let title = localizedString("achievement_modal_title", locale: Locale(identifier: "it"))
        let others = localizedString("achievement_modal_other_achievements", locale: Locale(identifier: "it"))
        XCTAssertTrue(title.localizedCaseInsensitiveContains("obiettivo"))
        XCTAssertTrue(others.localizedCaseInsensitiveContains("obiettivi"))
    }

    func testGivenVoiceOverControlAchievementWhenReadingLocalFallbackThenMatchesASCCopy() {
        XCTAssertEqual(
            AchievementIdentifier.controlVoiceOver.localizedTitle,
            "VoiceOver Controls"
        )
        XCTAssertEqual(
            AchievementIdentifier.controlVoiceOver.localizedAchievedDescription,
            "You completed a run using VoiceOver controls."
        )
    }

    func testGivenStreakAndOverlanderAchievementsWhenReadingLocalFallbackThenMatchesASCCopy() {
        XCTAssertEqual(AchievementIdentifier.runOvertakes100.localizedTitle, "Streak 100")
        XCTAssertEqual(
            AchievementIdentifier.runOvertakes100.localizedAchievedDescription,
            "You overtook 100 cars in one run."
        )
        XCTAssertEqual(AchievementIdentifier.totalOvertakes1k.localizedTitle, "Overlander 1K")
        XCTAssertEqual(
            AchievementIdentifier.totalOvertakes1k.localizedAchievedDescription,
            "You overtook 1,000 cars in total."
        )
        XCTAssertEqual(AchievementIdentifier.eventGAADAssistive.localizedTitle, "GAAD Assistive Week")
        XCTAssertEqual(
            AchievementIdentifier.eventGAADAssistive.localizedAchievedDescription,
            "You completed a run during GAAD week using assistive technology."
        )
    }

    func testGivenJapaneseLocaleWhenResolvingPlayThenUsesJapaneseCopy() {
        let value = localizedString("play", locale: Locale(identifier: "ja"))
        XCTAssertEqual(value, "プレイ")
    }

    func testGivenBrazilianPortugueseLocaleWhenResolvingSettingsThenUsesPortugueseCopy() {
        let value = localizedString("settings", locale: Locale(identifier: "pt-BR"))
        XCTAssertEqual(value, "Ajustes")
    }

    func testGivenEuropeanPortugueseLocaleWhenResolvingSettingsThenUsesEuropeanCopy() {
        let value = localizedString("settings", locale: Locale(identifier: "pt-PT"))
        XCTAssertEqual(value, "Definições")
    }

    func testGivenTraditionalChineseLocaleWhenResolvingPaywallTitleThenUsesChineseCopy() {
        let value = localizedString("paywall_title", locale: Locale(identifier: "zh-Hant"))
        XCTAssertTrue(value.contains("無限"))
    }

    func testGivenSimplifiedChineseLocaleWhenResolvingPaywallTitleThenUsesSimplifiedCopy() {
        let value = localizedString("paywall_title", locale: Locale(identifier: "zh-Hans"))
        XCTAssertTrue(value.contains("无限"))
    }

    func testGivenCanadianFrenchLocaleWhenResolvingSettingsThenUsesFrenchCopy() {
        let value = localizedString("settings", locale: Locale(identifier: "fr-CA"))
        XCTAssertEqual(value, "Réglages")
    }

    func testGivenTurkishLocaleWhenResolvingUnlimitedPlaysThenUsesApprovedTerm() {
        let value = localizedString("product_unlimited_plays", locale: Locale(identifier: "tr"))
        XCTAssertEqual(value, "Sınırsız Oyun")
    }

    func testGivenPolishLocaleWhenResolvingUnlimitedPlaysThenUsesApprovedTerm() {
        let value = localizedString("product_unlimited_plays", locale: Locale(identifier: "pl"))
        XCTAssertEqual(value, "Nielimitowane Gry")
    }

    func testGivenPreferredCaptureLocaleWhenResolvingViaGameLocalizedStringsThenUsesThatLocale() {
        let germanPlay = GameLocalizedStrings.string("play", preferredLocale: Locale(identifier: "de"))
        let dutchSettings = GameLocalizedStrings.string("settings", preferredLocale: Locale(identifier: "nl"))
        XCTAssertEqual(germanPlay, "Spielen")
        XCTAssertEqual(dutchSettings, "Instellingen")
    }

    func testGivenLocalizationDirectoryCandidatesWhenResolvingThenPrefersLanguageCodeFallback() {
        let candidates = GameLocalizedStrings.localizationDirectoryCandidates(
            for: Locale(identifier: "de_DE")
        )
        XCTAssertTrue(candidates.contains("de"))
        XCTAssertNotNil(GameLocalizedStrings.localizationBundle(for: Locale(identifier: "nl-NL")))
    }

    private func localizedString(_ key: String, locale: Locale) -> String {
        GameLocalizedStrings.string(key, preferredLocale: locale)
    }
}
