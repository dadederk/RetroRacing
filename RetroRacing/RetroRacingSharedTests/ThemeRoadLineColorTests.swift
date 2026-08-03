//
//  ThemeRoadLineColorTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 05/03/2026.
//

import XCTest
import SpriteKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
@testable import RetroRacingShared

final class ThemeRoadLineColorTests: XCTestCase {
    func testGivenPocketThemeWhenIncreaseContrastIsDisabledThenRoadLineColorMatchesNewPalette() {
        // Given
        let theme = PocketTheme()

        // When
        let roadLineColor = theme.roadLineColor(isIncreaseContrastEnabled: false).skColor

        // Then
        assertColor(roadLineColor, equals: SKColor(red: 95 / 255, green: 106 / 255, blue: 54 / 255, alpha: 1))
    }

    func testGivenPocketThemeWhenIncreaseContrastIsEnabledThenRoadLineColorMatchesHighContrastPalette() {
        // Given
        let theme = PocketTheme()

        // When
        let roadLineColor = theme.roadLineColor(isIncreaseContrastEnabled: true).skColor

        // Then
        assertColor(roadLineColor, equals: SKColor(red: 70 / 255, green: 78 / 255, blue: 40 / 255, alpha: 1))
    }

    func testGivenLCDThemeWhenIncreaseContrastIsDisabledThenRoadLineColorMatchesNewPalette() {
        // Given
        let theme = LCDTheme()

        // When
        let roadLineColor = theme.roadLineColor(isIncreaseContrastEnabled: false).skColor

        // Then
        assertColor(roadLineColor, equals: SKColor(red: 140 / 255, green: 134 / 255, blue: 121 / 255, alpha: 1))
    }

    func testGivenLCDThemeWhenIncreaseContrastIsEnabledThenRoadLineColorMatchesHighContrastPalette() {
        // Given
        let theme = LCDTheme()

        // When
        let roadLineColor = theme.roadLineColor(isIncreaseContrastEnabled: true).skColor

        // Then
        assertColor(roadLineColor, equals: SKColor(red: 110 / 255, green: 106 / 255, blue: 95 / 255, alpha: 1))
    }

    func testGivenEightBitThemeWhenIncreaseContrastIsDisabledThenRoadLineColorMatchesPalette() {
        // Given
        let theme = EightBitTheme()

        // When
        let roadLineColor = theme.roadLineColor(isIncreaseContrastEnabled: false).skColor

        // Then
        assertColor(roadLineColor, equals: SKColor(red: 255 / 255, green: 255 / 255, blue: 0 / 255, alpha: 1))
    }

    func testGivenEightBitThemeWhenIncreaseContrastIsEnabledThenRoadLineColorMatchesHighContrastPalette() {
        // Given
        let theme = EightBitTheme()

        // When
        let roadLineColor = theme.roadLineColor(isIncreaseContrastEnabled: true).skColor

        // Then
        assertColor(roadLineColor, equals: SKColor(red: 255 / 255, green: 255 / 255, blue: 102 / 255, alpha: 1))
    }

    func testGivenEightBitThemeWhenCheckingRoadSurfaceThenRoadColorMatchesGreyPalette() {
        // Given
        let theme = EightBitTheme()

        // When
        let roadColor = theme.gridCellColor().skColor

        // Then
        assertColor(roadColor, equals: SKColor(red: 136 / 255, green: 141 / 255, blue: 149 / 255, alpha: 1))
    }

    func testGivenEightBitThemeWhenCheckingRoadExteriorThenExteriorColorMatchesLightGreyPalette() throws {
        // Given
        let theme = EightBitTheme()

        // When
        let exteriorColor = try XCTUnwrap(theme.roadExteriorColor()?.skColor)

        // Then
        assertColor(exteriorColor, equals: SKColor(red: 174 / 255, green: 179 / 255, blue: 187 / 255, alpha: 1))
    }

    func testGivenSixteenBitThemeWhenCheckingRoadPaletteThenItTemporarilyMatchesEightBitRoadAndLinesWithGrassExterior() throws {
        // Given
        let theme = SixteenBitTheme()
        let eightBitTheme = EightBitTheme()

        // When / Then
        assertColor(theme.gridCellColor().skColor, equals: eightBitTheme.gridCellColor().skColor)
        assertColor(
            theme.roadLineColor(isIncreaseContrastEnabled: false).skColor,
            equals: eightBitTheme.roadLineColor(isIncreaseContrastEnabled: false).skColor
        )
        assertColor(
            theme.roadLineColor(isIncreaseContrastEnabled: true).skColor,
            equals: eightBitTheme.roadLineColor(isIncreaseContrastEnabled: true).skColor
        )
        assertColor(
            theme.lapMarkerColor(isIncreaseContrastEnabled: false).skColor,
            equals: eightBitTheme.lapMarkerColor(isIncreaseContrastEnabled: false).skColor
        )
        assertColor(
            theme.lapMarkerColor(isIncreaseContrastEnabled: true).skColor,
            equals: eightBitTheme.lapMarkerColor(isIncreaseContrastEnabled: true).skColor
        )
        assertColor(
            try XCTUnwrap(theme.roadExteriorColor()).skColor,
            equals: SKColor(red: 58 / 255, green: 151 / 255, blue: 76 / 255, alpha: 1)
        )
    }

    func testGivenHandheldThemesWhenCheckingRoadExteriorThenTheyUseSingleRoadColor() {
        // Given
        let themes: [GameTheme] = [PocketTheme(), LCDTheme()]

        // When / Then
        XCTAssertTrue(themes.allSatisfy { $0.roadExteriorColor() == nil })
    }

    func testGivenEightBitThemeWhenIncreaseContrastIsDisabledThenLapMarkerColorMatchesFinishPalette() {
        // Given
        let theme = EightBitTheme()

        // When
        let lapMarkerColor = theme.lapMarkerColor(isIncreaseContrastEnabled: false).skColor

        // Then
        assertColor(lapMarkerColor, equals: SKColor(red: 255 / 255, green: 248 / 255, blue: 232 / 255, alpha: 1))
    }

    func testGivenEightBitThemeWhenIncreaseContrastIsEnabledThenLapMarkerColorMatchesHighContrastFinishPalette() {
        // Given
        let theme = EightBitTheme()

        // When
        let lapMarkerColor = theme.lapMarkerColor(isIncreaseContrastEnabled: true).skColor

        // Then
        assertColor(lapMarkerColor, equals: SKColor.white)
    }

    func testGivenEightBitThemeWhenIncreaseContrastIsDisabledThenRoadLinesMeetMinimumContrast() {
        // Given
        let theme = EightBitTheme()
        let roadColor = theme.gridCellColor().skColor

        // When
        let roadLineContrast = ContrastColorResolver.contrastRatio(
            between: roadColor,
            and: theme.roadLineColor(isIncreaseContrastEnabled: false).skColor
        )
        let lapMarkerContrast = ContrastColorResolver.contrastRatio(
            between: roadColor,
            and: theme.lapMarkerColor(isIncreaseContrastEnabled: false).skColor
        )

        // Then
        XCTAssertTrue(roadLineContrast >= 3)
        XCTAssertTrue(lapMarkerContrast >= 3)
    }

    func testGivenEightBitThemeWhenIncreaseContrastIsEnabledThenRoadLinesMeetMinimumContrast() {
        // Given
        let theme = EightBitTheme()
        let roadColor = theme.gridCellColor().skColor

        // When
        let roadLineContrast = ContrastColorResolver.contrastRatio(
            between: roadColor,
            and: theme.roadLineColor(isIncreaseContrastEnabled: true).skColor
        )
        let lapMarkerContrast = ContrastColorResolver.contrastRatio(
            between: roadColor,
            and: theme.lapMarkerColor(isIncreaseContrastEnabled: true).skColor
        )

        // Then
        XCTAssertTrue(roadLineContrast >= 3)
        XCTAssertTrue(lapMarkerContrast >= 3)
    }

}
