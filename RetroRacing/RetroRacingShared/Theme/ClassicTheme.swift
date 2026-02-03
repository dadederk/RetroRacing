//
//  ClassicTheme.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import SwiftUI

/// Default LCD theme: pastel beige grid with LCD sprite family (playersCar-LCD, etc.).
public struct LCDTheme: GameTheme {
    public init() {}

    public var id: String { "lcd" }
    public var name: String { "LCD" }
    public var isPremium: Bool { false }

    public func backgroundColor(for state: GameState) -> Color {
        Color(red: 154 / 255, green: 220 / 255, blue: 38 / 255)
    }

    public func gridLineColor() -> Color { .gray }
    /// Pastel beige grid to differentiate from Game Boy.
    public func gridCellColor() -> Color {
        Color(red: 245 / 255, green: 235 / 255, blue: 210 / 255)
    }
    public func playerCarColor() -> Color { .blue }
    public func rivalCarColor() -> Color { .red }
    public func crashColor() -> Color { .orange }
    public func textColor() -> Color { .primary }

    public func cellBorderWidth() -> CGFloat { 1 }
    public func cornerRadius() -> CGFloat { 0 }

    public func playerCarSprite() -> String? { "playersCar-LCD" }
    public func rivalCarSprite() -> String? { "rivalsCar-LCD" }
    public func crashSprite() -> String? { "crash-LCD" }
    public func lifeSprite() -> String? { "life-LCD" }
}

/// Backward compatibility: ClassicTheme was renamed to LCDTheme (default LCD theme).
public typealias ClassicTheme = LCDTheme
