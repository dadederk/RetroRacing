//
//  GameTheme.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import SwiftUI

/// Visual theme contract defining colors, typography, and optional sprite assets.
public protocol GameTheme {
    var id: String { get }
    var name: String { get }
    var isPremium: Bool { get }

    func backgroundColor(for state: GameState) -> Color
    func gridLineColor() -> Color
    /// Grid cell fill color. Convert to SKColor in scene via `color.skColor`.
    func gridCellColor() -> Color
    func playerCarColor() -> Color
    func rivalCarColor() -> Color
    func crashColor() -> Color
    func textColor() -> Color

    func cellBorderWidth() -> CGFloat
    func cornerRadius() -> CGFloat

    /// Image asset name for player car; nil uses default.
    func playerCarSprite() -> String?
    /// Image asset name for rival car; nil uses default.
    func rivalCarSprite() -> String?
    /// Image asset name for crash; nil uses default.
    func crashSprite() -> String?
    /// Image asset name for life/hearts in header; nil uses default.
    func lifeSprite() -> String?
}

// Default implementations stay internal; conforming types can be public.
extension GameTheme {
    /// Default grid cell color (pastel beige).
    public func gridCellColor() -> Color {
        Color(red: 202 / 255, green: 220 / 255, blue: 159 / 255)
    }
    public func playerCarSprite() -> String? { nil }
    public func rivalCarSprite() -> String? { nil }
    public func crashSprite() -> String? { nil }
    public func lifeSprite() -> String? { nil }
}
