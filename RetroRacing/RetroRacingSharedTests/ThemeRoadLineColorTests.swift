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

    private func assertColor(
        _ color: SKColor,
        equals expected: SKColor,
        file: StaticString = #filePath,
        line: UInt = #line
    ) {
        guard let actualRGB = rgbComponents(from: color),
              let expectedRGB = rgbComponents(from: expected) else {
            XCTFail("Expected RGB-compatible colors", file: file, line: line)
            return
        }

        XCTAssertEqual(actualRGB.red, expectedRGB.red, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(actualRGB.green, expectedRGB.green, accuracy: 0.001, file: file, line: line)
        XCTAssertEqual(actualRGB.blue, expectedRGB.blue, accuracy: 0.001, file: file, line: line)
    }

    private func rgbComponents(from color: SKColor) -> (red: CGFloat, green: CGFloat, blue: CGFloat)? {
        #if canImport(UIKit)
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        if color.getRed(&red, green: &green, blue: &blue, alpha: &alpha) {
            return (red, green, blue)
        }
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB),
              let convertedColor = UIColor(cgColor: color.cgColor).cgColor.converted(
            to: colorSpace,
            intent: .defaultIntent,
            options: nil
        ),
              let components = convertedColor.components,
              components.count >= 3 else {
            return nil
        }
        return (components[0], components[1], components[2])
        #elseif canImport(AppKit)
        guard let sRGBColor = color.usingColorSpace(.sRGB) else {
            return nil
        }
        return (
            sRGBColor.redComponent,
            sRGBColor.greenComponent,
            sRGBColor.blueComponent
        )
        #else
        return nil
        #endif
    }
}
