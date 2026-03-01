//
//  ContrastColorResolverTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 01/03/2026.
//

import XCTest
import SpriteKit
@testable import RetroRacingShared

final class ContrastColorResolverTests: XCTestCase {
    func testGivenThemeRoadColorWhenResolvingLineColorThenContrastIsAtLeastFourPointFiveToOne() {
        // Given
        let roadColor = SKColor(red: 0.62, green: 0.74, blue: 0.31, alpha: 1)

        // When
        let resolvedColor = ContrastColorResolver.minimumDarkerColor(
            against: roadColor,
            minimumContrast: 4.5
        )
        let contrast = ContrastColorResolver.contrastRatio(
            between: roadColor,
            and: resolvedColor
        )

        // Then
        XCTAssertGreaterThanOrEqual(contrast, 4.5)
    }

    func testGivenLCDRoadColorWhenResolvingLineColorThenContrastPasses() {
        // Given
        let roadColor = LCDTheme().gridCellColor().skColor

        // When
        let resolvedColor = ContrastColorResolver.minimumDarkerColor(
            against: roadColor,
            minimumContrast: 4.5
        )
        let contrast = ContrastColorResolver.contrastRatio(
            between: roadColor,
            and: resolvedColor
        )

        // Then
        XCTAssertGreaterThanOrEqual(contrast, 4.5)
    }

    func testGivenPocketRoadColorWhenResolvingLineColorThenContrastPasses() {
        // Given
        let roadColor = PocketTheme().gridCellColor().skColor

        // When
        let resolvedColor = ContrastColorResolver.minimumDarkerColor(
            against: roadColor,
            minimumContrast: 4.5
        )
        let contrast = ContrastColorResolver.contrastRatio(
            between: roadColor,
            and: resolvedColor
        )

        // Then
        XCTAssertGreaterThanOrEqual(contrast, 4.5)
    }
}
