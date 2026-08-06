//
//  ThemeGalleryPreviewModelTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 04/08/2026.
//

import SpriteKit
import SwiftUI
import XCTest
@testable import RetroRacingShared

final class ThemeGalleryPreviewModelTests: XCTestCase {
    func testGivenConsoleEraThemesWhenReadingNamesThenUsesEvocativeDisplayNames() {
        let themes: [(theme: any GameTheme, expectedName: String)] = [
            (EightBitTheme(), "Cartridge"),
            (SixteenBitTheme(), "CRT"),
            (ThirtyTwoBitTheme(), "Disc"),
            (SixtyFourBitTheme(), "Polygon"),
        ]

        for testCase in themes {
            XCTAssertEqual(testCase.theme.name, testCase.expectedName)
        }
    }

    func testGivenBuiltInThemesWhenBuildingPreviewModelsThenAssetsUseGalleryOrder() {
        let cases: [(theme: any GameTheme, expectedAssetNames: [String])] = [
            (
                PocketTheme(),
                [
                    "playersCar-GameBoy",
                    "rivalsCar-GameBoy",
                    "life-GameBoy",
                    "friendLife-GameBoy",
                    "crash-GameBoy",
                ]
            ),
            (
                LCDTheme(),
                [
                    "playersCar-LCD",
                    "rivalsCar-LCD",
                    "life-LCD",
                    "friendLife-LCD",
                    "crash-LCD",
                ]
            ),
            (
                EightBitTheme(),
                [
                    "playersCar-8Bit",
                    "rivalsCar-8Bit",
                    "life-8Bit",
                    "friendLife-8Bit",
                    "crash-8Bit",
                ]
            ),
            (
                SixteenBitTheme(),
                [
                    "playersCar-16Bit",
                    "rivalsCar-16Bit",
                    "life-16Bit",
                    "friendLife-16Bit",
                    "crash-16Bit",
                ]
            ),
            (
                ThirtyTwoBitTheme(),
                [
                    "playersCar-32Bit",
                    "rivalsCar-32Bit",
                    "life-32Bit",
                    "friendLife-32Bit",
                    "crash-32Bit",
                ]
            ),
            (
                SixtyFourBitTheme(),
                [
                    "playersCar-64Bit",
                    "rivalsCar-64Bit",
                    "life-64Bit",
                    "friendLife-64Bit",
                    "crash-64Bit",
                ]
            ),
        ]

        for testCase in cases {
            let model = ThemeGalleryPreviewModel(
                theme: testCase.theme,
                isIncreaseContrastEnabled: false
            )

            XCTAssertEqual(model.assets.map(\.role), ThemeGalleryPreviewAssetRole.allCases)
            XCTAssertEqual(model.assets.map(\.assetName), testCase.expectedAssetNames)
        }
    }

    func testGivenThemeWithoutOptionalAssetsWhenBuildingPreviewModelThenLCDFallbacksAreUsed() {
        let theme = GalleryFallbackTheme()

        let model = ThemeGalleryPreviewModel(
            theme: theme,
            isIncreaseContrastEnabled: false
        )

        XCTAssertEqual(model.assets.map(\.assetName), [
            "playersCar-LCD",
            "rivalsCar-LCD",
            "life-LCD",
            "life-LCD",
            "crash-LCD",
        ])
    }

    func testGivenBuiltInThemesWhenBuildingPreviewModelsThenAccessibilityDescriptionsUseThemeSpecificKeys() {
        let cases: [(theme: any GameTheme, expectedKey: String)] = [
            (PocketTheme(), "settings_theme_gallery_preview_accessibility_pocket"),
            (LCDTheme(), "settings_theme_gallery_preview_accessibility_lcd"),
            (EightBitTheme(), "settings_theme_gallery_preview_accessibility_eight_bit"),
            (SixteenBitTheme(), "settings_theme_gallery_preview_accessibility_sixteen_bit"),
            (ThirtyTwoBitTheme(), "settings_theme_gallery_preview_accessibility_thirty_two_bit"),
            (SixtyFourBitTheme(), "settings_theme_gallery_preview_accessibility_sixty_four_bit"),
        ]

        for testCase in cases {
            let model = ThemeGalleryPreviewModel(
                theme: testCase.theme,
                isIncreaseContrastEnabled: false
            )

            XCTAssertEqual(model.accessibilityDescriptionKey, testCase.expectedKey)
            XCTAssertFalse(model.accessibilityDescription.isEmpty)
            XCTAssertTrue(model.accessibilityDescription.contains(testCase.theme.name))
        }
    }

    func testGivenUnknownThemeWhenBuildingPreviewModelThenAccessibilityDescriptionFallsBackToThemeName() {
        let theme = GalleryFallbackTheme()

        let model = ThemeGalleryPreviewModel(
            theme: theme,
            isIncreaseContrastEnabled: false
        )

        XCTAssertEqual(model.accessibilityDescriptionKey, ThemeGalleryPreviewModel.genericAccessibilityDescriptionKey)
        XCTAssertTrue(model.accessibilityDescription.contains(theme.name))
    }

    func testGivenCurrentThemeWhenSelectingGalleryPreviewThenNoActionIsReturned() {
        let action = ThemeGallerySelectionPolicy.action(
            previewID: .lcd,
            currentThemeID: .lcd,
            isThemeAvailable: true
        )

        XCTAssertEqual(action, .none)
    }

    func testGivenAvailableDifferentThemeWhenSelectingGalleryPreviewThenSelectionActionIsReturned() {
        let action = ThemeGallerySelectionPolicy.action(
            previewID: .eightBit,
            currentThemeID: .lcd,
            isThemeAvailable: true
        )

        XCTAssertEqual(action, .selectTheme)
    }

    func testGivenLockedDifferentThemeWhenSelectingGalleryPreviewThenPaywallActionIsReturned() {
        let action = ThemeGallerySelectionPolicy.action(
            previewID: .sixteenBit,
            currentThemeID: .lcd,
            isThemeAvailable: false
        )

        XCTAssertEqual(action, .presentPaywall)
    }

    func testGivenThemeWhenBuildingPreviewModelThenPaletteUsesRoadExteriorAndFinishLineOrder() throws {
        let theme = EightBitTheme()

        let model = ThemeGalleryPreviewModel(
            theme: theme,
            isIncreaseContrastEnabled: false
        )

        XCTAssertEqual(model.palette.swatches.map(\.role), ThemeGalleryPaletteRole.allCases)
        assertColor(model.palette.road.skColor, equals: theme.gridCellColor().skColor)
        assertColor(model.palette.roadLine.skColor, equals: theme.roadLineColor(isIncreaseContrastEnabled: false).skColor)
        assertColor(model.palette.roadExterior.skColor, equals: try XCTUnwrap(theme.roadExteriorColor()).skColor)
        assertColor(model.palette.finishLine.skColor, equals: theme.lapMarkerColor(isIncreaseContrastEnabled: false).skColor)
    }

    func testGivenThemeWithoutRoadExteriorWhenBuildingPreviewModelThenRoadColorIsReused() {
        let theme = LCDTheme()

        let model = ThemeGalleryPreviewModel(
            theme: theme,
            isIncreaseContrastEnabled: false
        )

        assertColor(model.palette.roadExterior.skColor, equals: theme.gridCellColor().skColor)
    }

    func testGivenIncreaseContrastWhenBuildingPreviewModelThenLineAndFinishColorsUseHighContrastVariants() {
        let theme = SixteenBitTheme()

        let model = ThemeGalleryPreviewModel(
            theme: theme,
            isIncreaseContrastEnabled: true
        )

        assertColor(model.palette.roadLine.skColor, equals: theme.roadLineColor(isIncreaseContrastEnabled: true).skColor)
        assertColor(model.palette.finishLine.skColor, equals: theme.lapMarkerColor(isIncreaseContrastEnabled: true).skColor)
    }
}

private struct GalleryFallbackTheme: GameTheme {
    var id: ThemeID { ThemeID(rawValue: "gallery-fallback") }
    var name: String { "Fallback" }
    var isPremium: Bool { false }

    func backgroundColor(for state: GameState) -> Color { .clear }
    func gridLineColor() -> Color { .gray }
    func playerCarColor() -> Color { .blue }
    func rivalCarColor() -> Color { .red }
    func crashColor() -> Color { .orange }
    func textColor() -> Color { .primary }
    func cellBorderWidth() -> CGFloat { 1 }
    func cornerRadius() -> CGFloat { 0 }
}
