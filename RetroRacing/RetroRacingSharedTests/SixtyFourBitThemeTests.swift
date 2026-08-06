//
//  SixtyFourBitThemeTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation
import ImageIO
import SpriteKit
import XCTest
@testable import RetroRacingShared

final class SixtyFourBitThemeTests: XCTestCase {
    private let theme = SixtyFourBitTheme()

    func testGivenSixtyFourBitThemeWhenReadingIdentityAndAssetsThenMatchesExperimentalContract() {
        XCTAssertEqual(theme.id, .sixtyFourBit)
        XCTAssertEqual(theme.name, "Polygon")
        XCTAssertFalse(theme.isPremium)
        XCTAssertEqual(theme.cellBorderWidth(), 1)
        XCTAssertEqual(theme.cornerRadius(), 0)
        XCTAssertEqual(theme.playerCarSprite(), "playersCar-64Bit")
        XCTAssertEqual(theme.rivalCarSprite(), "rivalsCar-64Bit")
        XCTAssertEqual(theme.crashSprite(), "crash-64Bit")
        XCTAssertEqual(theme.lifeSprite(), "life-64Bit")
        XCTAssertEqual(theme.friendLifeSprite(), "friendLife-64Bit")
    }

    func testGivenSixtyFourBitThemeWhenReadingPaletteThenColorsMatchContract() throws {
        assertColor(
            theme.gridCellColor().skColor,
            equals: SKColor(red: 23 / 255, green: 26 / 255, blue: 36 / 255, alpha: 1)
        )
        assertColor(
            try XCTUnwrap(theme.roadExteriorColor()).skColor,
            equals: SKColor(red: 13 / 255, green: 46 / 255, blue: 41 / 255, alpha: 1)
        )
        assertColor(
            theme.roadLineColor(isIncreaseContrastEnabled: false).skColor,
            equals: .white
        )
        assertColor(
            theme.lapMarkerColor(isIncreaseContrastEnabled: false).skColor,
            equals: SKColor(red: 74 / 255, green: 226 / 255, blue: 218 / 255, alpha: 1)
        )
        assertColor(theme.roadLineColor(isIncreaseContrastEnabled: true).skColor, equals: .white)
        assertColor(theme.lapMarkerColor(isIncreaseContrastEnabled: true).skColor, equals: .white)
    }

    func testGivenSixtyFourBitRoadMarkersWhenComparedWithRoadThenContrastMeetsThreeToOne() {
        let roadColor = theme.gridCellColor().skColor
        let markerColors = [
            theme.roadLineColor(isIncreaseContrastEnabled: false).skColor,
            theme.roadLineColor(isIncreaseContrastEnabled: true).skColor,
            theme.lapMarkerColor(isIncreaseContrastEnabled: false).skColor,
            theme.lapMarkerColor(isIncreaseContrastEnabled: true).skColor,
        ]

        for markerColor in markerColors {
            XCTAssertGreaterThanOrEqual(
                ContrastColorResolver.contrastRatio(between: roadColor, and: markerColor),
                3
            )
        }
    }

    func testGivenSixtyFourBitTextWhenComparedWithRelevantBackgroundsThenContrastMeetsFourPointFiveToOne() throws {
        let textColor = theme.textColor().skColor
        let backgrounds = [
            theme.gridCellColor().skColor,
            try XCTUnwrap(theme.roadExteriorColor()).skColor,
        ]

        for background in backgrounds {
            XCTAssertGreaterThanOrEqual(
                ContrastColorResolver.contrastRatio(between: background, and: textColor),
                4.5
            )
        }
    }

    func testGivenSixtyFourBitSpriteCatalogWhenInspectingFamiliesThenEveryPlatformVariantDecodes() throws {
        let families = ["playersCar", "rivalsCar", "crash", "life", "friendLife"]
        let idioms = ["iphone", "ipad", "mac", "watch", "tv"]

        for family in families {
            let imagesetURL = spriteCatalogURL.appendingPathComponent("\(family)-64Bit.imageset")
            let contentsData = try Data(contentsOf: imagesetURL.appendingPathComponent("Contents.json"))
            let contents = try XCTUnwrap(JSONSerialization.jsonObject(with: contentsData) as? [String: Any])
            let images = try XCTUnwrap(contents["images"] as? [[String: String]])
            XCTAssertEqual(Set(images.compactMap { $0["idiom"] }), Set(idioms))

            for idiom in idioms {
                let filename = "\(family)-64Bit-\(idiom).png"
                let source = try XCTUnwrap(
                    CGImageSourceCreateWithURL(imagesetURL.appendingPathComponent(filename) as CFURL, nil),
                    "Expected \(filename) to decode"
                )
                XCTAssertEqual(CGImageSourceGetCount(source), 1)
            }
        }
    }

    private var spriteCatalogURL: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .appendingPathComponent("RetroRacingShared/Assets.xcassets/Sprites/64Bit")
    }
}
