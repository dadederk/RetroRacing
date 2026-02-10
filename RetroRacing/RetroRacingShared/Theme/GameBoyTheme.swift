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

    /// Lightened Game Boy-inspired background for better contrast with car sprites.
    public func backgroundColor(for state: GameState) -> Color {
        Color(red: 200 / 255, green: 220 / 255, blue: 130 / 255)
    }

    /// Grid lines stay close to the playfield tone while still reading as separators.
    public func gridLineColor() -> Color {
        Color(red: 143 / 255, green: 161 / 255, blue: 82 / 255)
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

    /// Light green playfield to keep a Game Boy look with improved car contrast.
    public func gridCellColor() -> Color {
        Color(red: 175 / 255, green: 197 / 255, blue: 102 / 255)
    }

    public func cellBorderWidth() -> CGFloat { 1 }
    public func cornerRadius() -> CGFloat { 0 }

    public func playerCarSprite() -> String? { "playersCar-GameBoy" }
    public func rivalCarSprite() -> String? { "rivalsCar-GameBoy" }
    public func crashSprite() -> String? { "crash-GameBoy" }
    public func lifeSprite() -> String? { "life-GameBoy" }
}
