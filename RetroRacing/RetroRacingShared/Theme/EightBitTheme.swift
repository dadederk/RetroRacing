//
//  EightBitTheme.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 02/08/2026.
//

import Foundation
import SwiftUI

/// Vivid 8-bit home-console-inspired theme with a medium arcade-grey road and colorful sprite family.
public struct EightBitTheme: GameTheme {
    public let isPremium: Bool

    public init() {
        self.init(isPremium: false)
    }

    public init(isPremium: Bool) {
        self.isPremium = isPremium
    }

    public var id: ThemeID { .eightBit }
    public var name: String { "8-Bit" }

    public func backgroundColor(for state: GameState) -> Color {
        Color(red: 174 / 255, green: 179 / 255, blue: 187 / 255)
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
        Color(red: 174 / 255, green: 179 / 255, blue: 187 / 255)
    }

    public func playerCarColor() -> Color {
        Color(red: 226 / 255, green: 46 / 255, blue: 36 / 255)
    }

    public func rivalCarColor() -> Color {
        Color(red: 56 / 255, green: 88 / 255, blue: 214 / 255)
    }

    public func crashColor() -> Color {
        Color(red: 255 / 255, green: 135 / 255, blue: 31 / 255)
    }

    public func textColor() -> Color {
        Color(red: 255 / 255, green: 245 / 255, blue: 214 / 255)
    }

    public func cellBorderWidth() -> CGFloat { 1 }
    public func cornerRadius() -> CGFloat { 0 }

    public func playerCarSprite() -> String? { "playersCar-8Bit" }
    public func rivalCarSprite() -> String? { "rivalsCar-8Bit" }
    public func crashSprite() -> String? { "crash-8Bit" }
    public func lifeSprite() -> String? { "life-8Bit" }
    public func friendLifeSprite() -> String? { "friendLife-8Bit" }
}
