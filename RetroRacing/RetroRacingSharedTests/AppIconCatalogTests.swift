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

    func testGivenReleasedStylesWhenResolvingGalleryThenFuturePlatformIconsStayHidden() {
        // Given
        let releasedThemeIDs: Set<ThemeID> = [.pocket, .lcd, .eightBit, .sixteenBit]

        // When
        let options = AppIconCatalog.availableOptions(availableThemeIDs: releasedThemeIDs)

        // Then
        XCTAssertEqual(options.map(\.id), [
            .classic,
            .pocket,
            .lcd,
            .cartridge,
            .crt,
            .retroCartridge,
            .retroVideoGame,
            .retroGameBox,
        ])
        XCTAssertFalse(AppIconCatalog.isAvailable(.disc, availableThemeIDs: releasedThemeIDs))
        XCTAssertFalse(AppIconCatalog.isAvailable(.polygon, availableThemeIDs: releasedThemeIDs))
    }

    func testGivenFutureStylesWhenResolvingGalleryThenMatchingIconsJoinInCatalogOrder() {
        // Given
        let futureThemeIDs: Set<ThemeID> = [
            .pocket, .lcd, .eightBit, .sixteenBit, .thirtyTwoBit, .sixtyFourBit,
        ]

        // When
        let options = AppIconCatalog.availableOptions(availableThemeIDs: futureThemeIDs)

        // Then
        XCTAssertEqual(options, AppIconCatalog.options)
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
