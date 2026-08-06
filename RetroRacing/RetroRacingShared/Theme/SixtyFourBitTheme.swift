//
//  SixtyFourBitTheme.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 06/08/2026.
//

import Foundation
import SwiftUI

/// Late-1990s low-poly console theme derived from the visionOS 64-Bit art direction.
public struct SixtyFourBitTheme: GameTheme {
    public let isPremium: Bool

    public init() {
        self.init(isPremium: false)
    }

    public init(isPremium: Bool) {
        self.isPremium = isPremium
    }

    public var id: ThemeID { .sixtyFourBit }
    public var name: String { "Polygon" }

    public func backgroundColor(for state: GameState) -> Color {
        roadExteriorColor() ?? gridCellColor()
    }

    public func gridLineColor() -> Color {
        roadLineColor(isIncreaseContrastEnabled: false)
    }

    public func roadLineColor(isIncreaseContrastEnabled: Bool) -> Color {
        .white
    }

    public func lapMarkerColor(isIncreaseContrastEnabled: Bool) -> Color {
        isIncreaseContrastEnabled
            ? .white
            : Color(red: 74 / 255, green: 226 / 255, blue: 218 / 255)
    }

    public func gridCellColor() -> Color {
        Color(red: 23 / 255, green: 26 / 255, blue: 36 / 255)
    }

    public func roadExteriorColor() -> Color? {
        Color(red: 13 / 255, green: 46 / 255, blue: 41 / 255)
    }

    public func playerCarColor() -> Color {
        Color(red: 255 / 255, green: 56 / 255, blue: 85 / 255)
    }

    public func rivalCarColor() -> Color {
        Color(red: 43 / 255, green: 217 / 255, blue: 255 / 255)
    }

    public func crashColor() -> Color {
        Color(red: 255 / 255, green: 153 / 255, blue: 31 / 255)
    }

    public func textColor() -> Color {
        Color(red: 255 / 255, green: 247 / 255, blue: 232 / 255)
    }

    public func cellBorderWidth() -> CGFloat { 1 }
    public func cornerRadius() -> CGFloat { 0 }

    public func playerCarSprite() -> String? { "playersCar-64Bit" }
    public func rivalCarSprite() -> String? { "rivalsCar-64Bit" }
    public func crashSprite() -> String? { "crash-64Bit" }
    public func lifeSprite() -> String? { "life-64Bit" }
    public func friendLifeSprite() -> String? { "friendLife-64Bit" }
}
