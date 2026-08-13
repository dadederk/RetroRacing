//
//  FontPreferenceStoreTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 13/08/2026.
//

import Foundation
import SwiftUI
import XCTest
@testable import RetroRacingShared

@MainActor
final class FontPreferenceStoreTests: XCTestCase {
    func testGivenFontCatalogWhenReadingCasesThenOrderAndIdentifiersAreStableAndUnique() {
        // Given / When
        let styles = AppFontStyle.allCases

        // Then
        XCTAssertEqual(
            styles,
            [.custom, .system, .systemMonospaced, .openDyslexic, .atkinsonHyperlegible, .lexend]
        )
        XCTAssertEqual(Set(styles.map(\.rawValue)).count, styles.count)
        XCTAssertEqual(AppFontStyle.custom.rawValue, "custom")
        XCTAssertEqual(AppFontStyle.storageKey, "selectedFontStyle")
    }

    func testGivenBundledFamiliesWhenReadingFacesThenPostScriptNamesAndWeightsMatchResources() {
        // Given / When / Then
        XCTAssertEqual(faceSummary(for: .custom), ["PressStart2P-Regular:0"])
        XCTAssertEqual(
            faceSummary(for: .openDyslexic),
            ["OpenDyslexic-Regular:0", "OpenDyslexic-Bold:3"]
        )
        XCTAssertEqual(
            faceSummary(for: .atkinsonHyperlegible),
            [
                "AtkinsonHyperlegibleNext-Regular:0",
                "AtkinsonHyperlegibleNext-Bold:3",
                "AtkinsonHyperlegibleNext-ExtraBold:4"
            ]
        )
        XCTAssertEqual(
            faceSummary(for: .lexend),
            ["Lexend-Regular:0", "Lexend-Bold:3", "Lexend-ExtraBold:4"]
        )
        XCTAssertTrue(AppFontStyle.system.availableFaces.isEmpty)
        XCTAssertTrue(AppFontStyle.systemMonospaced.availableFaces.isEmpty)
    }

    func testGivenNoStoredValueWhenInitializingThenPressStartRemainsDefault() throws {
        // Given
        let defaults = try makeDefaults(named: "default")

        // When
        let store = FontPreferenceStore(userDefaults: defaults, availability: completeAvailability)

        // Then
        XCTAssertEqual(store.currentStyle, .custom)
        XCTAssertEqual(store.effectiveStyle, .custom)
    }

    func testGivenEveryFontStyleWhenSelectingThenRawValuePersists() throws {
        // Given
        let defaults = try makeDefaults(named: "persistence")
        let store = FontPreferenceStore(userDefaults: defaults, availability: completeAvailability)

        for style in AppFontStyle.allCases {
            // When
            store.currentStyle = style

            // Then
            XCTAssertEqual(defaults.string(forKey: AppFontStyle.storageKey), style.rawValue)
        }
    }

    func testGivenLegacyStoredValuesWhenInitializingThenExistingSelectionsArePreserved() throws {
        for style in [AppFontStyle.custom, .system, .systemMonospaced] {
            // Given
            let defaults = try makeDefaults(named: "legacy-\(style.rawValue)")
            defaults.set(style.rawValue, forKey: AppFontStyle.storageKey)

            // When
            let store = FontPreferenceStore(userDefaults: defaults, availability: completeAvailability)

            // Then
            XCTAssertEqual(store.currentStyle, style)
        }
    }

    func testGivenInvalidStoredValueWhenInitializingThenPressStartIsSelectedWithoutRewritingStorage() throws {
        // Given
        let defaults = try makeDefaults(named: "invalid")
        defaults.set("future-font", forKey: AppFontStyle.storageKey)

        // When
        let store = FontPreferenceStore(userDefaults: defaults, availability: completeAvailability)

        // Then
        XCTAssertEqual(store.currentStyle, .custom)
        XCTAssertEqual(defaults.string(forKey: AppFontStyle.storageKey), "future-font")
    }

    func testGivenUnavailableStoredFamilyWhenInitializingThenSelectionIsPreservedAndSystemIsEffective() throws {
        // Given
        let defaults = try makeDefaults(named: "unavailable")
        defaults.set(AppFontStyle.lexend.rawValue, forKey: AppFontStyle.storageKey)

        // When
        let store = FontPreferenceStore(userDefaults: defaults, availability: .systemOnly)

        // Then
        XCTAssertEqual(store.currentStyle, .lexend)
        XCTAssertEqual(store.effectiveStyle, .system)
        XCTAssertEqual(defaults.string(forKey: AppFontStyle.storageKey), AppFontStyle.lexend.rawValue)
    }

    func testGivenPreviouslyUnavailableSelectionWhenFacesReturnOnNextLaunchThenFamilyRestores() throws {
        // Given
        let defaults = try makeDefaults(named: "restoration")
        defaults.set(AppFontStyle.openDyslexic.rawValue, forKey: AppFontStyle.storageKey)
        let unavailableStore = FontPreferenceStore(userDefaults: defaults, availability: .systemOnly)
        XCTAssertEqual(unavailableStore.effectiveStyle, .system)

        // When
        let restoredStore = FontPreferenceStore(userDefaults: defaults, availability: completeAvailability)

        // Then
        XCTAssertEqual(restoredStore.currentStyle, .openDyslexic)
        XCTAssertEqual(restoredStore.effectiveStyle, .openDyslexic)
    }

    func testGivenSemanticStylesWhenResolvingBaselineThenEveryValueIsPositiveAndOrdered() {
        // Given
        let styles: [Font.TextStyle] = [.caption2, .caption, .footnote, .body, .title3, .title2, .title, .largeTitle]

        // When
        let sizes = styles.map(AppFontResolver.basePointSize(for:))

        // Then
        XCTAssertTrue(sizes.allSatisfy { $0 > 0 })
        XCTAssertEqual(sizes, sizes.sorted())
    }

    func testGivenSemiboldRequestWhenOnlyRegularAndBoldExistThenNearestBoldFaceIsUsed() {
        // Given
        let availability = availability(for: .openDyslexic)

        // When
        let face = AppFontResolver.resolvedFace(
            for: .openDyslexic,
            textStyle: .body,
            availability: availability,
            legibilityWeight: nil,
            requestedWeightTier: .semibold
        )

        // Then
        XCTAssertEqual(face?.postScriptName, "OpenDyslexic-Bold")
    }

    func testGivenMissingRequestedWeightWhenResolvingThenNearestRegisteredFaceIsUsed() {
        // Given
        let regularOnly = AppFontAvailability(
            availablePostScriptNames: ["AtkinsonHyperlegibleNext-Regular"]
        )

        // When
        let face = AppFontResolver.resolvedFace(
            for: .atkinsonHyperlegible,
            textStyle: .headline,
            availability: regularOnly,
            legibilityWeight: nil,
            requestedWeightTier: .heavy
        )

        // Then
        XCTAssertEqual(face?.weightTier, .regular)
    }

    func testGivenBoldTextWhenResolvingCustomFamilyThenNextBundledFaceIsPromoted() {
        // Given
        let availability = availability(for: .lexend)

        // When
        let regularFace = AppFontResolver.resolvedFace(
            for: .lexend,
            textStyle: .body,
            availability: availability,
            legibilityWeight: nil
        )
        let boldTextFace = AppFontResolver.resolvedFace(
            for: .lexend,
            textStyle: .body,
            availability: availability,
            legibilityWeight: .bold
        )

        // Then
        XCTAssertEqual(regularFace?.weightTier, .regular)
        XCTAssertEqual(boldTextFace?.weightTier, .bold)
    }

    func testGivenHeadlineAndBoldTextWhenExtraBoldExistsThenSemanticBoldPromotesToExtraBold() {
        // Given / When
        let face = AppFontResolver.resolvedFace(
            for: .atkinsonHyperlegible,
            textStyle: .headline,
            availability: availability(for: .atkinsonHyperlegible),
            legibilityWeight: .bold
        )

        // Then
        XCTAssertEqual(face?.weightTier, .heavy)
    }

    func testGivenMissingFamilyWhenResolvingTypographyThenSystemFallbackIsEffective() {
        // Given
        let typography = AppTypography(selectedStyle: .lexend, availability: .systemOnly)

        // When / Then
        XCTAssertEqual(typography.selectedStyle, .lexend)
        XCTAssertEqual(typography.effectiveStyle, .system)
        _ = AppFontResolver.font(for: .body, typography: typography)
    }

    func testGivenEnvironmentValuesWhenCreatedThenTypographyHasNonOptionalSystemDefault() {
        // Given / When
        let environment = EnvironmentValues()

        // Then
        XCTAssertEqual(environment.appTypography, .system)
        XCTAssertNil(environment.fontPreferenceStore)
    }

    func testGivenBundledLicenseWhenLoadingThenFullOFLTextIsAvailable() {
        // Given / When
        let license = AppFontLicenseTextProvider.silOpenFontLicenseText

        // Then
        XCTAssertTrue(license.hasPrefix("SIL OPEN FONT LICENSE"))
        XCTAssertTrue(license.contains("PERMISSION & CONDITIONS"))
        XCTAssertFalse(license.contains(GameLocalizedStrings.string("font_license_unavailable")))
    }

    func testGivenGameplayStylesWhenReadingHUDRolesThenBothPlatformsUseTitleOneAndTitleTwo() {
        // Given
        let styles = [GameViewStyle.universal, .tvOS]

        // When / Then
        XCTAssertTrue(styles.allSatisfy { $0.hudTextStyle == .title })
        XCTAssertTrue(styles.allSatisfy { $0.friendHUDTextStyle == .title2 })
        XCTAssertFalse(GameViewStyle.universal.preservesVerticalSafeAreaMargins)
        XCTAssertTrue(GameViewStyle.tvOS.preservesVerticalSafeAreaMargins)
    }

    func testGivenPlatformStylesWhenReadingPresentationThenSemanticAdaptiveContractsRemain() {
        XCTAssertEqual(MenuViewStyle.universal.utilityActionPlacement, .toolbar)
        XCTAssertEqual(MenuViewStyle.universal.destinationPresentation, .sheet)
        XCTAssertEqual(MenuViewStyle.tvOS.utilityActionPlacement, .content)
        XCTAssertEqual(MenuViewStyle.tvOS.destinationPresentation, .navigation)
        XCTAssertEqual(SettingsViewStyle.universal.layout, .sections)
        XCTAssertEqual(SettingsViewStyle.tvOS.layout, .categories)
    }

    private var completeAvailability: AppFontAvailability {
        AppFontAvailability(
            availablePostScriptNames: Set(
                AppFontStyle.allCases.flatMap(\.availableFaces).map(\.postScriptName)
            )
        )
    }

    private func availability(for style: AppFontStyle) -> AppFontAvailability {
        AppFontAvailability(
            availablePostScriptNames: Set(style.availableFaces.map(\.postScriptName))
        )
    }

    private func faceSummary(for style: AppFontStyle) -> [String] {
        style.availableFaces.map { "\($0.postScriptName):\($0.weightTier.rawValue)" }
    }

    private func makeDefaults(named name: String) throws -> UserDefaults {
        let suiteName = "FontPreferenceStoreTests.\(name)"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        addTeardownBlock { defaults.removePersistentDomain(forName: suiteName) }
        return defaults
    }
}
