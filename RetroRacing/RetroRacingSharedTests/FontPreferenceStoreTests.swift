//
//  FontPreferenceStoreTests.swift
//  RetroRacingSharedTests
//

import XCTest
import SwiftUI
@testable import RetroRacingShared

@MainActor
final class FontPreferenceStoreTests: XCTestCase {

    func testGivenNoStoredFontStyleWhenInitializingThenCustomStyleIsSelected() {
        // Given
        let defaults = UserDefaults(suiteName: "FontPreferenceStoreTests.initial")!
        defaults.removeObject(forKey: AppFontStyle.storageKey)
        defer { defaults.removeObject(forKey: AppFontStyle.storageKey) }

        // When
        let store = FontPreferenceStore(userDefaults: defaults, customFontAvailable: true)

        // Then
        XCTAssertEqual(store.currentStyle, .custom)
    }

    func testGivenFontStyleStoreWhenSettingStyleThenSelectionIsPersisted() {
        // Given
        let defaults = UserDefaults(suiteName: "FontPreferenceStoreTests.set")!
        defaults.removeObject(forKey: AppFontStyle.storageKey)
        defer { defaults.removeObject(forKey: AppFontStyle.storageKey) }

        let store = FontPreferenceStore(userDefaults: defaults, customFontAvailable: true)

        // When
        store.currentStyle = .systemMonospaced

        // Then
        XCTAssertEqual(store.currentStyle, .systemMonospaced)
        XCTAssertEqual(defaults.string(forKey: AppFontStyle.storageKey), AppFontStyle.systemMonospaced.rawValue)
    }

    func testGivenStoredCustomStyleWhenCustomFontIsUnavailableThenSystemStyleIsSelected() {
        // Given
        let defaults = UserDefaults(suiteName: "FontPreferenceStoreTests.unavailable")!
        defaults.set(AppFontStyle.custom.rawValue, forKey: AppFontStyle.storageKey)
        defer { defaults.removeObject(forKey: AppFontStyle.storageKey) }

        // When
        let store = FontPreferenceStore(userDefaults: defaults, customFontAvailable: false)

        // Then
        XCTAssertEqual(store.currentStyle, .system)
        XCTAssertFalse(store.isCustomFontAvailable)
    }

    func testGivenSemanticTextStylesWhenRequestingCustomBaseSizesThenExpectedLegacySizesAreUsed() {
        // Given
        let expected: [(Font.TextStyle, CGFloat)] = [
            (.caption2, 11),
            (.caption, 12),
            (.subheadline, 15),
            (.body, 17),
            (.headline, 17),
            (.title, 28)
        ]

        // When
        let actual = expected.map { style, _ in
            (style, AppFontStyle.defaultCustomPointSize(for: style))
        }

        // Then
        XCTAssertEqual(actual.map(\.1), expected.map(\.1))
    }

    func testGivenEachFontStyleWhenRequestingSemanticBodyFontThenFontCanBeConstructed() {
        // Given
        let styles = AppFontStyle.allCases

        // When
        let fonts = styles.map { AppFontStyle.semanticFont(for: $0, textStyle: .body) }

        // Then
        XCTAssertEqual(fonts.count, styles.count)
    }

    func testGivenUniversalGameViewStyleWhenReadingHUDTextStyleThenSubheadlineIsUsed() {
        // Given
        let style = GameViewStyle.universal

        // When
        let hudTextStyle = style.hudTextStyle

        // Then
        XCTAssertEqual(hudTextStyle, .subheadline)
    }

    func testGivenTvOSGameViewStyleWhenReadingHUDTextStyleThenTitleIsUsed() {
        // Given
        let style = GameViewStyle.tvOS

        // When
        let hudTextStyle = style.hudTextStyle

        // Then
        XCTAssertEqual(hudTextStyle, .title)
    }
}
