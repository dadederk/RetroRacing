//
//  ThirtyTwoBitTheme.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 05/08/2026.
//

import Foundation
import SwiftUI

/// Experimental late-1990s console theme with an electric circuit and dark asphalt.
public struct ThirtyTwoBitTheme: GameTheme {
    public let isPremium: Bool

    public init() {
        self.init(isPremium: false)
    }

    public init(isPremium: Bool) {
        self.isPremium = isPremium
    }

    public var id: ThemeID { .thirtyTwoBit }
    public var name: String { "Disc" }

    public func backgroundColor(for state: GameState) -> Color {
        roadExteriorColor() ?? gridCellColor()
    }

    public func gridLineColor() -> Color {
        roadLineColor(isIncreaseContrastEnabled: false)
    }

    public func roadLineColor(isIncreaseContrastEnabled: Bool) -> Color {
        isIncreaseContrastEnabled
            ? .white
            : Color(red: 111 / 255, green: 255 / 255, blue: 233 / 255)
    }

    public func lapMarkerColor(isIncreaseContrastEnabled: Bool) -> Color {
        isIncreaseContrastEnabled
            ? .white
            : Color(red: 255 / 255, green: 224 / 255, blue: 102 / 255)
    }

    public func gridCellColor() -> Color {
        Color(red: 59 / 255, green: 64 / 255, blue: 80 / 255)
    }

    public func roadExteriorColor() -> Color? {
        Color(red: 7 / 255, green: 91 / 255, blue: 91 / 255)
    }

    public func playerCarColor() -> Color {
        Color(red: 255 / 255, green: 56 / 255, blue: 85 / 255)
    }

    public func rivalCarColor() -> Color {
        Color(red: 67 / 255, green: 217 / 255, blue: 255 / 255)
    }

    public func crashColor() -> Color {
        Color(red: 255 / 255, green: 177 / 255, blue: 51 / 255)
    }

    public func textColor() -> Color {
        Color(red: 255 / 255, green: 247 / 255, blue: 232 / 255)
    }

    public func cellBorderWidth() -> CGFloat { 1 }
    public func cornerRadius() -> CGFloat { 0 }

    public func playerCarSprite() -> String? { "playersCar-32Bit" }
    public func rivalCarSprite() -> String? { "rivalsCar-32Bit" }
    public func crashSprite() -> String? { "crash-32Bit" }
    public func lifeSprite() -> String? { "life-32Bit" }
    public func friendLifeSprite() -> String? { "friendLife-32Bit" }
}
