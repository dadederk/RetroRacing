import Foundation
import SwiftUI

/// Default free theme: light green background, simple clean aesthetic.
public struct ClassicTheme: GameTheme {
    public init() {}

    public var id: String { "classic" }
    public var name: String { "Classic" }
    public var isPremium: Bool { false }

    public func backgroundColor(for state: GameState) -> Color {
        Color(red: 154 / 255, green: 220 / 255, blue: 38 / 255)
    }

    public func gridLineColor() -> Color { .gray }
    public func playerCarColor() -> Color { .blue }
    public func rivalCarColor() -> Color { .red }
    public func crashColor() -> Color { .orange }
    public func textColor() -> Color { .primary }

    public func cellBorderWidth() -> CGFloat { 1 }
    public func cornerRadius() -> CGFloat { 0 }
}
