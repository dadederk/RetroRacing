//
//  FontPreferenceStoreTests.swift
//  RetroRacingSharedTests
//

import XCTest
import Foundation
import SwiftUI
@testable import RetroRacingShared

@MainActor
final class FontPreferenceStoreTests: XCTestCase {

    func testGivenNoStoredFontStyleWhenInitializingThenCustomStyleIsSelected() throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "FontPreferenceStoreTests.initial"))
        defaults.removeObject(forKey: AppFontStyle.storageKey)
        defer { defaults.removeObject(forKey: AppFontStyle.storageKey) }

        // When
        let store = FontPreferenceStore(userDefaults: defaults, customFontAvailable: true)

        // Then
        XCTAssertTrue(store.currentStyle == .custom)
    }

    func testGivenFontStyleStoreWhenSettingStyleThenSelectionIsPersisted() throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "FontPreferenceStoreTests.set"))
        defaults.removeObject(forKey: AppFontStyle.storageKey)
        defer { defaults.removeObject(forKey: AppFontStyle.storageKey) }

        let store = FontPreferenceStore(userDefaults: defaults, customFontAvailable: true)

        // When
        store.currentStyle = .systemMonospaced

        // Then
        XCTAssertTrue(store.currentStyle == .systemMonospaced)
        XCTAssertTrue(defaults.string(forKey: AppFontStyle.storageKey) == AppFontStyle.systemMonospaced.rawValue)
    }

    func testGivenStoredCustomStyleWhenCustomFontIsUnavailableThenSystemStyleIsSelected() throws {
        // Given
        let defaults = try XCTUnwrap(UserDefaults(suiteName: "FontPreferenceStoreTests.unavailable"))
        defaults.set(AppFontStyle.custom.rawValue, forKey: AppFontStyle.storageKey)
        defer { defaults.removeObject(forKey: AppFontStyle.storageKey) }

        // When
        let store = FontPreferenceStore(userDefaults: defaults, customFontAvailable: false)

        // Then
        XCTAssertTrue(store.currentStyle == .system)
        XCTAssertTrue(store.isCustomFontAvailable == false)
    }

    func testGivenSemanticTextStylesWhenRequestingCustomBaseSizesThenExpectedLegacySizesAreUsed() {
        // Given
        var expected: [(Font.TextStyle, CGFloat)] = [
            (.caption2, 11),
            (.caption, 12),
            (.subheadline, 15),
            (.body, 17),
            (.headline, 17),
            (.title, 28)
        ]
        #if os(macOS)
        expected.append(contentsOf: [
            (.extraLargeTitle2, 36),
            (.extraLargeTitle, 44)
        ])
        #endif

        // When
        let actual = expected.map { style, _ in
            (style, AppFontStyle.defaultCustomPointSize(for: style))
        }

        // Then
        XCTAssertTrue(actual.map(\.1) == expected.map(\.1))
    }

    func testGivenEachFontStyleWhenRequestingSemanticBodyFontThenFontCanBeConstructed() {
        // Given
        let styles = AppFontStyle.allCases

        // When
        let fonts = styles.map { AppFontStyle.semanticFont(for: $0, textStyle: .body) }

        // Then
        XCTAssertTrue(fonts.count == styles.count)
    }

    func testGivenUniversalGameViewStyleWhenReadingHUDTextStyleThenTitleIsUsed() {
        // Given
        let style = GameViewStyle.universal

        // When
        let hudTextStyle = style.hudTextStyle

        // Then
        XCTAssertTrue(hudTextStyle == .title)
    }

    func testGivenGameViewStylesWhenComparingHUDTextAndLifeIconsThenBaseSizesMatch() {
        // Given
        let styles = [GameViewStyle.universal, .tvOS]

        // When
        let baseSizesMatch = styles.map {
            $0.lifeIconSize == AppFontStyle.defaultCustomPointSize(for: $0.hudTextStyle)
        }

        // Then
        XCTAssertTrue(baseSizesMatch.allSatisfy { $0 })
    }

    func testGivenGameViewStylesWhenReadingFriendHUDThenItUsesTitleTwo() {
        // Given
        let styles = [GameViewStyle.universal, .tvOS]

        // When
        let friendTextStyles = styles.map(\.friendHUDTextStyle)
        let friendBaseSizesMatch = styles.map {
            $0.friendLifeIconSize == AppFontStyle.defaultCustomPointSize(for: $0.friendHUDTextStyle)
        }

        // Then
        XCTAssertTrue(friendTextStyles == [.title2, .title2])
        XCTAssertTrue(friendBaseSizesMatch.allSatisfy { $0 })
    }

    func testGivenTvOSGameViewStyleWhenReadingHUDTextStyleThenTitleIsUsed() {
        // Given
        let style = GameViewStyle.tvOS

        // When
        let hudTextStyle = style.hudTextStyle

        // Then
        XCTAssertTrue(hudTextStyle == .title)
    }
}
