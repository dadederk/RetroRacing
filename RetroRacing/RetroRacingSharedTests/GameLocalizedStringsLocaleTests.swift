//
//  GameLocalizedStringsLocaleTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 23/07/2026.
//

import XCTest

@testable import RetroRacingShared

final class GameLocalizedStringsLocaleTests: XCTestCase {
    private let bundle = Bundle(for: GameScene.self)

    private let checkpointKeys = [
        "play",
        "settings",
        "game_over_encouragement_title",
        "paywall_limit_notice",
        "menu_engagement_prompt",
        "shareplay_activity_title",
    ]

    private let supportedLocales = ["de", "nl", "it", "fr", "es", "ca"]

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

    private func localizedString(_ key: String, locale: Locale) -> String {
        String(
            localized: String.LocalizationValue(stringLiteral: key),
            bundle: bundle,
            locale: locale
        )
    }
}
