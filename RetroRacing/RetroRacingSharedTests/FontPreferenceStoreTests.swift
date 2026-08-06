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

    func testGivenUniversalGameViewStyleWhenComparingHUDTextAndLifeIconsThenBaseSizesMatch() {
        // Given
        let style = GameViewStyle.universal

        // When
        let baseSizesMatch = style.lifeIconSize == AppFontStyle.defaultCustomPointSize(for: style.hudTextStyle)

        // Then
        XCTAssertTrue(baseSizesMatch)
    }

    func testGivenGameViewStylesWhenReadingFriendHUDThenItUsesPlatformScale() {
        // Given
        let styles = [GameViewStyle.universal, .tvOS]

        // When
        let friendTextStyles = styles.map(\.friendHUDTextStyle)
        let friendBaseSizesMatch = styles.map {
            $0.friendLifeIconSize == AppFontStyle.defaultCustomPointSize(for: $0.friendHUDTextStyle)
        }

        // Then
        XCTAssertTrue(friendTextStyles == [.title2, .largeTitle])
        XCTAssertTrue(friendBaseSizesMatch == [true, false])
    }

    func testGivenTvOSGameViewStyleWhenReadingHUDMetricsThenFixedLargeTitleScaleIsUsed() {
        // Given
        let style = GameViewStyle.tvOS

        // When
        let hudTextStyle = style.hudTextStyle

        // Then
        XCTAssertTrue(hudTextStyle == .largeTitle)
        XCTAssertTrue(style.usesFixedHUDMetrics)
        XCTAssertEqual(style.hudFontSize, 44)
        XCTAssertEqual(style.lifeIconSize, 56)
        XCTAssertEqual(style.compactSideRailWidth, 300)
        XCTAssertFalse(style.showsGameplayToolbarControls)
        XCTAssertTrue(style.preservesVerticalSafeAreaMargins)
        XCTAssertFalse(GameViewStyle.universal.preservesVerticalSafeAreaMargins)
    }

    func testGivenPlatformMenuStylesWhenReadingUtilityPresentationThenTvOSUsesContentNavigation() {
        XCTAssertFalse(MenuViewStyle.universal.showsHelpAction)
        XCTAssertEqual(MenuViewStyle.universal.utilityActionPlacement, .toolbar)
        XCTAssertEqual(MenuViewStyle.universal.destinationPresentation, .sheet)

        XCTAssertTrue(MenuViewStyle.tvOS.showsHelpAction)
        XCTAssertEqual(MenuViewStyle.tvOS.utilityActionPlacement, .content)
        XCTAssertEqual(MenuViewStyle.tvOS.destinationPresentation, .navigation)
    }

    func testGivenPlatformSettingsStylesWhenReadingLayoutThenOnlyTvOSUsesCategories() {
        XCTAssertEqual(SettingsViewStyle.universal.layout, .sections)
        XCTAssertEqual(SettingsViewStyle.universal.presentation, .modal)
        XCTAssertTrue(SettingsViewStyle.universal.showsDirectTouch)

        XCTAssertEqual(SettingsViewStyle.tvOS.layout, .categories)
        XCTAssertEqual(SettingsViewStyle.tvOS.presentation, .navigationDestination)
        XCTAssertFalse(SettingsViewStyle.tvOS.showsDirectTouch)
    }
}
