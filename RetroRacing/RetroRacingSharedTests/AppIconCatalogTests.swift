//
//  AppIconCatalogTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 13/08/2026.
//

import XCTest
@testable import RetroRacingShared

final class AppIconCatalogTests: XCTestCase {
    func testGivenCatalogWhenReadingEntriesThenOrderAndCompatibilityDataAreStable() throws {
        // Given / When
        let options = AppIconCatalog.options

        // Then
        XCTAssertEqual(options.map(\.id), [
            .classic,
            .pocket,
            .lcd,
            .cartridge,
            .crt,
            .disc,
            .polygon,
            .retroCartridge,
            .retroVideoGame,
            .retroGameBox,
        ])
        XCTAssertEqual(Set(options.map(\.id)).count, 10)
        XCTAssertEqual(Set(AppIconCatalog.alternateSystemIconNames).count, 9)
        XCTAssertEqual(AppIconCatalog.options.first?.systemIconName, nil)
        XCTAssertEqual(AppIconCatalog.options(in: .classic).count, 1)
        XCTAssertEqual(AppIconCatalog.options(in: .themes).count, 6)
        XCTAssertEqual(AppIconCatalog.options(in: .specialEditions).count, 3)

        XCTAssertEqual(
            AppIconCatalog.option(for: .retroCartridge)?.systemIconName,
            "RetroRapidGameCartridge"
        )
        XCTAssertEqual(
            AppIconCatalog.option(for: .retroVideoGame)?.systemIconName,
            "RetroRapidVideoGame"
        )
        XCTAssertEqual(
            AppIconCatalog.option(for: .retroGameBox)?.systemIconName,
            "RetroRapidGameBox"
        )
        XCTAssertEqual(AppIconCatalog.option(forSystemIconName: nil)?.id, .classic)
        XCTAssertEqual(
            options.map(\.previewAssetName),
            [
                "AppIconPreviewClassic",
                "AppIconPreviewPocket",
                "AppIconPreviewLCD",
                "AppIconPreviewCartridge",
                "AppIconPreviewCRT",
                "AppIconPreviewDisc",
                "AppIconPreviewPolygon",
                "AppIconPreviewRetroCartridge",
                "AppIconPreviewRetroVideoGame",
                "AppIconPreviewRetroGameBox",
            ]
        )
        XCTAssertEqual(Set(options.map(\.previewAssetName)).count, 10)
    }

    func testGivenEntitlementStatesWhenSelectingIconsThenExpectedActionsAreReturned() throws {
        // Given
        let classic = try XCTUnwrap(AppIconCatalog.option(for: .classic))
        let pocket = try XCTUnwrap(AppIconCatalog.option(for: .pocket))

        // When / Then
        XCTAssertEqual(action(for: classic, current: .classic), .none)
        XCTAssertEqual(action(for: classic, current: .pocket), .selectIcon)
        XCTAssertEqual(
            action(for: pocket, current: .classic, hasAccess: true, isResolved: false),
            .selectIcon
        )
        XCTAssertEqual(
            action(for: pocket, current: .classic, hasAccess: false, isResolved: false),
            .waitForEntitlement
        )
        XCTAssertEqual(
            action(for: pocket, current: .classic, hasAccess: false, isResolved: true),
            .presentPaywall
        )
        XCTAssertEqual(
            action(for: pocket, current: .pocket, hasAccess: false, isResolved: true),
            .none
        )
    }

    @MainActor
    func testGivenProductionFlagWhenCallerAttemptsToEnableThenItRemainsDisabled() throws {
        // Given
        let suiteName = "AppIconCatalogTests.productionFeatureFlag"
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suiteName))
        defaults.removePersistentDomain(forName: suiteName)
        defer { defaults.removePersistentDomain(forName: suiteName) }
        defaults.set("enabled", forKey: ReleaseFeature.alternateIcons.storageKey)
        let store = ReleaseFeatureStore(platform: .iPhone, userDefaults: defaults, allowsOverrides: false)
        let featureFlag = ReleaseAppIconFeatureFlag(features: store)

        // When
        featureFlag.setEnabled(true)

        // Then
        XCTAssertFalse(featureFlag.isEnabled)
    }

    private func action(
        for option: AppIconOption,
        current: AppIconID?,
        hasAccess: Bool = false,
        isResolved: Bool = true
    ) -> AppIconSelectionAction {
        AppIconSelectionPolicy.action(
            option: option,
            currentIconID: current,
            hasUnlimitedAccessForGating: hasAccess,
            hasResolvedInitialEntitlements: isResolved
        )
    }
}
