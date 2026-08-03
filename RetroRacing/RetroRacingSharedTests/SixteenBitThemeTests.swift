//
//  SixteenBitThemeTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 02/08/2026.
//

import XCTest
import Foundation
import ImageIO
import SpriteKit
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif
@testable import RetroRacingShared

final class SixteenBitThemeTests: XCTestCase {
    private let theme = SixteenBitTheme()

    func testGivenSixteenBitThemeWhenReadingIdentityAndGeometryThenMatchesContract() {
        // Given
        let theme = theme

        // When
        let themeID = theme.id

        // Then
        XCTAssertTrue(themeID == .sixteenBit)
        XCTAssertTrue(theme.name == "16-Bit")
        XCTAssertTrue(theme.isPremium == false)
        XCTAssertTrue(theme.cellBorderWidth() == 1)
        XCTAssertTrue(theme.cornerRadius() == 0)
        XCTAssertTrue(theme.playerCarSprite() == "playersCar-16Bit")
        XCTAssertTrue(theme.rivalCarSprite() == "rivalsCar-16Bit")
        XCTAssertTrue(theme.crashSprite() == "crash-16Bit")
        XCTAssertTrue(theme.lifeSprite() == "life-16Bit")
        XCTAssertTrue(theme.friendLifeSprite() == "friendLife-16Bit")
    }

    func testGivenSixteenBitThemeWhenReadingPaletteThenColorsMatchContract() throws {
        // Given
        let theme = theme

        // When
        let backgroundColor = theme.backgroundColor(for: GameState()).skColor

        // Then
        assertColor(
            backgroundColor,
            equals: SKColor(red: 58 / 255, green: 151 / 255, blue: 76 / 255, alpha: 1)
        )
        assertColor(
            theme.gridCellColor().skColor,
            equals: SKColor(red: 136 / 255, green: 141 / 255, blue: 149 / 255, alpha: 1)
        )
        assertColor(
            try XCTUnwrap(theme.roadExteriorColor()).skColor,
            equals: SKColor(red: 58 / 255, green: 151 / 255, blue: 76 / 255, alpha: 1)
        )
        assertColor(
            theme.roadLineColor(isIncreaseContrastEnabled: false).skColor,
            equals: SKColor(red: 255 / 255, green: 255 / 255, blue: 0 / 255, alpha: 1)
        )
        assertColor(
            theme.roadLineColor(isIncreaseContrastEnabled: true).skColor,
            equals: SKColor(red: 255 / 255, green: 255 / 255, blue: 102 / 255, alpha: 1)
        )
        assertColor(
            theme.lapMarkerColor(isIncreaseContrastEnabled: false).skColor,
            equals: SKColor(red: 255 / 255, green: 248 / 255, blue: 232 / 255, alpha: 1)
        )
        assertColor(theme.lapMarkerColor(isIncreaseContrastEnabled: true).skColor, equals: .white)
        assertColor(
            theme.rivalCarColor().skColor,
            equals: SKColor(red: 38 / 255, green: 198 / 255, blue: 218 / 255, alpha: 1)
        )
        assertColor(
            theme.crashColor().skColor,
            equals: SKColor(red: 255 / 255, green: 138 / 255, blue: 51 / 255, alpha: 1)
        )
        assertColor(
            theme.textColor().skColor,
            equals: SKColor(red: 18 / 255, green: 24 / 255, blue: 38 / 255, alpha: 1)
        )
    }

    func testGivenSixteenBitPlayerColorWhenReadingComponentsThenUsesExactRGB565Normalization() throws {
        // Given
        let playerColor = theme.playerCarColor().skColor

        // When
        let components = try XCTUnwrap(rgbComponents(from: playerColor))

        // Then
        XCTAssertTrue(abs(components.red - (31.0 / 31.0)) <= 0.0001)
        XCTAssertTrue(abs(components.green - (11.0 / 63.0)) <= 0.0001)
        XCTAssertTrue(abs(components.blue - (10.0 / 31.0)) <= 0.0001)
        let rgb565Signature = (31 << 11) | (11 << 5) | 10
        XCTAssertTrue(rgb565Signature == 0xF96A)
    }

    func testGivenSixteenBitRoadMarkersWhenComparedWithRoadThenContrastMeetsThreeToOne() {
        // Given
        let roadColor = theme.gridCellColor().skColor
        let markerColors = [
            theme.roadLineColor(isIncreaseContrastEnabled: false).skColor,
            theme.roadLineColor(isIncreaseContrastEnabled: true).skColor,
            theme.lapMarkerColor(isIncreaseContrastEnabled: false).skColor,
            theme.lapMarkerColor(isIncreaseContrastEnabled: true).skColor
        ]

        // When
        let contrastRatios = markerColors.map {
            ContrastColorResolver.contrastRatio(between: roadColor, and: $0)
        }

        // Then
        for contrastRatio in contrastRatios {
            XCTAssertTrue(contrastRatio >= 3)
        }
    }

    func testGivenSixteenBitTextWhenComparedWithRelevantBackgroundsThenContrastMeetsFourPointFiveToOne() throws {
        // Given
        let textColor = theme.textColor().skColor
        let relevantBackgrounds = [
            theme.gridCellColor().skColor,
            try XCTUnwrap(theme.roadExteriorColor()).skColor
        ]

        // When
        let contrastRatios = relevantBackgrounds.map {
            ContrastColorResolver.contrastRatio(between: $0, and: textColor)
        }

        // Then
        for contrastRatio in contrastRatios {
            XCTAssertTrue(contrastRatio >= 4.5)
        }
    }

    func testGivenSixteenBitSpriteCatalogWhenInspectingFamiliesThenEveryPlatformVariantDecodes() throws {
        // Given
        let families = ["playersCar", "rivalsCar", "crash", "life", "friendLife"]
        let idioms = ["iphone", "ipad", "mac", "watch", "tv"]

        // When / Then
        for family in families {
            let imagesetURL = spriteCatalogURL.appendingPathComponent("\(family)-16Bit.imageset")
            let contentsURL = imagesetURL.appendingPathComponent("Contents.json")
            let contentsData = try Data(contentsOf: contentsURL)
            let contents = try XCTUnwrap(JSONSerialization.jsonObject(with: contentsData) as? [String: Any])
            let images = try XCTUnwrap(contents["images"] as? [[String: String]])
            XCTAssertTrue(Set(images.compactMap { $0["idiom"] }) == Set(idioms))

            for idiom in idioms {
                let filename = "\(family)-16Bit-\(idiom).png"
                let imageURL = imagesetURL.appendingPathComponent(filename)
                let source = try XCTUnwrap(
                    CGImageSourceCreateWithURL(imageURL as CFURL, nil),
                    "Expected \(filename) to decode"
                )
                XCTAssertTrue(CGImageSourceGetCount(source) == 1)
            }
        }
    }

    func testGivenSixteenBitPlayerSpriteWhenInspectingRedRampThenItUsesRGB565RepresentableShades() throws {
        // Given
        let family = "playersCar"

        // When
        let colors = try spriteColors(family: family)

        // Then
        XCTAssertTrue(
            sixteenBitRedRamp.isSubset(of: colors),
            "Missing RGB565 ramp colors: \(sixteenBitRedRamp.subtracting(colors))"
        )
        XCTAssertTrue(colors.contains(RGBColor(red: 255, green: 45, blue: 82)))
    }

    func testGivenSixteenBitLifeSpriteWhenInspectingPaletteThenItPreservesRedRampAndLightMarking() throws {
        // Given
        let family = "life"

        // When
        let colors = try spriteColors(family: family)

        // Then
        XCTAssertTrue(
            sixteenBitRedRamp.isSubset(of: colors),
            "Missing RGB565 ramp colors: \(sixteenBitRedRamp.subtracting(colors))"
        )
        XCTAssertTrue(colors.contains(RGBColor(red: 255, green: 241, blue: 193)))
    }

    func testGivenSixteenBitRivalAndCrashSpritesWhenInspectingPaletteThenSignatureDetailsRemainReadable() throws {
        // Given
        let rivalFamily = "rivalsCar"
        let crashFamily = "crash"

        // When
        let rivalColors = try spriteColors(family: rivalFamily)
        let crashColors = try spriteColors(family: crashFamily)

        // Then
        XCTAssertTrue(rivalColors.contains(RGBColor(red: 38, green: 198, blue: 218)))
        XCTAssertTrue(rivalColors.contains(RGBColor(red: 255, green: 45, blue: 82)))
        XCTAssertTrue(rivalColors.contains(RGBColor(red: 255, green: 241, blue: 193)))

        XCTAssertTrue(crashColors.contains(RGBColor(red: 255, green: 138, blue: 51)))
        XCTAssertTrue(crashColors.contains(RGBColor(red: 38, green: 198, blue: 218)))
        XCTAssertTrue(crashColors.contains(RGBColor(red: 90, green: 82, blue: 101)))
    }

    private var spriteCatalogURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("RetroRacingShared/Assets.xcassets/Sprites/16Bit")
    }

    private var sixteenBitRedRamp: Set<RGBColor> {
        [
            RGBColor(red: 18, green: 3, blue: 4).expandedFromRGB565,
            RGBColor(red: 25, green: 7, blue: 7).expandedFromRGB565,
            RGBColor(red: 31, green: 11, blue: 10).expandedFromRGB565,
            RGBColor(red: 31, green: 18, blue: 13).expandedFromRGB565,
            RGBColor(red: 31, green: 25, blue: 16).expandedFromRGB565
        ]
    }

    private func spriteColors(family: String) throws -> Set<RGBColor> {
        let imageURL = spriteCatalogURL
            .appendingPathComponent("\(family)-16Bit.imageset")
            .appendingPathComponent("\(family)-16Bit-mac.png")
        let source = try XCTUnwrap(CGImageSourceCreateWithURL(imageURL as CFURL, nil))
        let cgImage = try XCTUnwrap(CGImageSourceCreateImageAtIndex(source, 0, nil))
        return try rgbaColors(in: cgImage)
    }

    private func rgbaColors(in image: CGImage) throws -> Set<RGBColor> {
        let bytesPerPixel = 4
        let bytesPerRow = image.width * bytesPerPixel
        var bytes = [UInt8](repeating: 0, count: bytesPerRow * image.height)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = try XCTUnwrap(
            CGContext(
                data: &bytes,
                width: image.width,
                height: image.height,
                bitsPerComponent: 8,
                bytesPerRow: bytesPerRow,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                    | CGBitmapInfo.byteOrder32Big.rawValue
            )
        )
        context.draw(image, in: CGRect(x: 0, y: 0, width: image.width, height: image.height))

        var colors: Set<RGBColor> = []
        for index in stride(from: 0, to: bytes.count, by: bytesPerPixel) where bytes[index + 3] > 0 {
            colors.insert(RGBColor(red: bytes[index], green: bytes[index + 1], blue: bytes[index + 2]))
        }
        return colors
    }

}

private struct RGBColor: Hashable {
    let red: UInt8
    let green: UInt8
    let blue: UInt8

    var expandedFromRGB565: RGBColor {
        RGBColor(
            red: UInt8((Int(red) * 255 + 15) / 31),
            green: UInt8((Int(green) * 255 + 31) / 63),
            blue: UInt8((Int(blue) * 255 + 15) / 31)
        )
    }
}
