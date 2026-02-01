import Foundation
import SwiftUI

/// Visual theme for the game. Implementations define colors, styles, and optional sprite names.
public protocol GameTheme {
    var id: String { get }
    var name: String { get }
    var isPremium: Bool { get }

    func backgroundColor(for state: GameState) -> Color
    func gridLineColor() -> Color
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
}

// Default implementations stay internal; conforming types can be public.
extension GameTheme {
    public func playerCarSprite() -> String? { nil }
    public func rivalCarSprite() -> String? { nil }
    public func crashSprite() -> String? { nil }
}

