//
//  ThirtyTwoBitThemeTests.swift
//  RetroRacingSharedTests
//
//  Created by Dani Devesa on 05/08/2026.
//

import Foundation
import ImageIO
import SpriteKit
import XCTest
@testable import RetroRacingShared

final class ThirtyTwoBitThemeTests: XCTestCase {
    private let theme = ThirtyTwoBitTheme()

    func testGivenThirtyTwoBitThemeWhenReadingIdentityAndAssetsThenMatchesExperimentalContract() {
        XCTAssertEqual(theme.id, .thirtyTwoBit)
        XCTAssertEqual(theme.name, "Disc")
        XCTAssertFalse(theme.isPremium)
        XCTAssertEqual(theme.cellBorderWidth(), 1)
        XCTAssertEqual(theme.cornerRadius(), 0)
        XCTAssertEqual(theme.playerCarSprite(), "playersCar-32Bit")
        XCTAssertEqual(theme.rivalCarSprite(), "rivalsCar-32Bit")
        XCTAssertEqual(theme.crashSprite(), "crash-32Bit")
        XCTAssertEqual(theme.lifeSprite(), "life-32Bit")
        XCTAssertEqual(theme.friendLifeSprite(), "friendLife-32Bit")
    }

    func testGivenThirtyTwoBitThemeWhenReadingPaletteThenColorsMatchContract() throws {
        assertColor(
            theme.gridCellColor().skColor,
            equals: SKColor(red: 59 / 255, green: 64 / 255, blue: 80 / 255, alpha: 1)
        )
        assertColor(
            try XCTUnwrap(theme.roadExteriorColor()).skColor,
            equals: SKColor(red: 7 / 255, green: 91 / 255, blue: 91 / 255, alpha: 1)
        )
        assertColor(
            theme.roadLineColor(isIncreaseContrastEnabled: false).skColor,
            equals: SKColor(red: 111 / 255, green: 255 / 255, blue: 233 / 255, alpha: 1)
        )
        assertColor(
            theme.lapMarkerColor(isIncreaseContrastEnabled: false).skColor,
            equals: SKColor(red: 255 / 255, green: 224 / 255, blue: 102 / 255, alpha: 1)
        )
        assertColor(theme.roadLineColor(isIncreaseContrastEnabled: true).skColor, equals: .white)
        assertColor(theme.lapMarkerColor(isIncreaseContrastEnabled: true).skColor, equals: .white)
    }

    func testGivenThirtyTwoBitRoadMarkersWhenComparedWithRoadThenContrastMeetsThreeToOne() {
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

    func testGivenThirtyTwoBitTextWhenComparedWithRelevantBackgroundsThenContrastMeetsFourPointFiveToOne() throws {
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

    func testGivenThirtyTwoBitSpriteCatalogWhenInspectingFamiliesThenEveryPlatformVariantDecodes() throws {
        let families = ["playersCar", "rivalsCar", "crash", "life", "friendLife"]
        let variants = [
            (idiom: "iphone", filenameSuffix: "iphone"),
            (idiom: "ipad", filenameSuffix: "ipad"),
            (idiom: "mac", filenameSuffix: "mac"),
            (idiom: "watch", filenameSuffix: "watch"),
            (idiom: "tv", filenameSuffix: "tv"),
            (idiom: "universal", filenameSuffix: "vision")
        ]

        for family in families {
            let imagesetURL = spriteCatalogURL.appendingPathComponent("\(family)-32Bit.imageset")
            let contentsData = try Data(contentsOf: imagesetURL.appendingPathComponent("Contents.json"))
            let contents = try XCTUnwrap(JSONSerialization.jsonObject(with: contentsData) as? [String: Any])
            let images = try XCTUnwrap(contents["images"] as? [[String: String]])
            XCTAssertEqual(
                Set(images.compactMap { $0["idiom"] }),
                Set(variants.map { $0.idiom })
            )

            for variant in variants {
                let filename = "\(family)-32Bit-\(variant.filenameSuffix).png"
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
            .appendingPathComponent("RetroRacingShared/Assets.xcassets/Sprites/32Bit")
    }
}
