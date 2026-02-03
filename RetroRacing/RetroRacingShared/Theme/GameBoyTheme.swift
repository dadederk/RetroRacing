//
//  GameBoyTheme.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import SwiftUI

/// Free theme capturing the monochrome green Game Boy aesthetic.
public struct GameBoyTheme: GameTheme {
    public init() {}

    public var id: String { "gameboy" }
    public var name: String { "Game Boy" }
    public var isPremium: Bool { false }

    /// Classic Game Boy background green #9BBC0F
    public func backgroundColor(for state: GameState) -> Color {
        Color(red: 0.608, green: 0.737, blue: 0.059)
    }

    /// Dark green #0F380F for foreground/grid
    public func gridLineColor() -> Color {
        Color(red: 0.059, green: 0.220, blue: 0.059)
    }

    public func playerCarColor() -> Color {
        Color(red: 0.059, green: 0.220, blue: 0.059)
    }

    public func rivalCarColor() -> Color {
        Color(red: 0.324, green: 0.549, blue: 0.027)
    }

    public func crashColor() -> Color {
        Color(red: 0.059, green: 0.220, blue: 0.059)
    }

    public func textColor() -> Color {
        Color(red: 0.059, green: 0.220, blue: 0.059)
    }

    /// Dark green #0F380F for grid cells.
    public func gridCellColor() -> Color {
        Color(red: 0.059, green: 0.220, blue: 0.059)
    }

    public func cellBorderWidth() -> CGFloat { 1 }
    public func cornerRadius() -> CGFloat { 0 }

    public func playerCarSprite() -> String? { "playersCar-GameBoy" }
    public func rivalCarSprite() -> String? { "rivalsCar-GameBoy" }
    public func crashSprite() -> String? { "crash-GameBoy" }
    public func lifeSprite() -> String? { "life-GameBoy" }
}
