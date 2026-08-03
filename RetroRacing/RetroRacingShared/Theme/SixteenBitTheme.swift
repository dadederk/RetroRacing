//
//  SixteenBitTheme.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 02/08/2026.
//

import Foundation
import SwiftUI

/// Early-1990s 16-bit arcade theme with a grass exterior and grey perspective road.
public struct SixteenBitTheme: GameTheme {
    public let isPremium: Bool

    public init() {
        self.init(isPremium: false)
    }

    public init(isPremium: Bool) {
        self.isPremium = isPremium
    }

    public var id: ThemeID { .sixteenBit }
    public var name: String { "16-Bit" }

    public func backgroundColor(for state: GameState) -> Color {
        Color(red: 58 / 255, green: 151 / 255, blue: 76 / 255)
    }

    public func gridLineColor() -> Color {
        roadLineColor(isIncreaseContrastEnabled: false)
    }

    public func roadLineColor(isIncreaseContrastEnabled: Bool) -> Color {
        ArcadeRoadPalette.line(isIncreaseContrastEnabled: isIncreaseContrastEnabled)
    }

    public func lapMarkerColor(isIncreaseContrastEnabled: Bool) -> Color {
        ArcadeRoadPalette.lapMarker(isIncreaseContrastEnabled: isIncreaseContrastEnabled)
    }

    public func gridCellColor() -> Color {
        ArcadeRoadPalette.surface
    }

    public func roadExteriorColor() -> Color? {
        Color(red: 58 / 255, green: 151 / 255, blue: 76 / 255)
    }

    public func playerCarColor() -> Color {
        Color(red: 31 / 31, green: 11 / 63, blue: 10 / 31)
    }

    public func rivalCarColor() -> Color {
        Color(red: 38 / 255, green: 198 / 255, blue: 218 / 255)
    }

    public func crashColor() -> Color {
        Color(red: 255 / 255, green: 138 / 255, blue: 51 / 255)
    }

    public func textColor() -> Color {
        Color(red: 18 / 255, green: 24 / 255, blue: 38 / 255)
    }

    public func cellBorderWidth() -> CGFloat { 1 }
    public func cornerRadius() -> CGFloat { 0 }

    public func playerCarSprite() -> String? { "playersCar-16Bit" }
    public func rivalCarSprite() -> String? { "rivalsCar-16Bit" }
    public func crashSprite() -> String? { "crash-16Bit" }
    public func lifeSprite() -> String? { "life-16Bit" }
    public func friendLifeSprite() -> String? { "friendLife-16Bit" }
}
