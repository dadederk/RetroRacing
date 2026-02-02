import SwiftUI
import SpriteKit

#if canImport(UIKit)
import UIKit

extension Color {
    /// Converts SwiftUI Color to SKColor (UIColor on iOS/tvOS/watchOS) for use in SpriteKit.
    public var skColor: SKColor {
        UIColor(self)
    }
}
#elseif canImport(AppKit)
import AppKit

extension Color {
    /// Converts SwiftUI Color to SKColor (NSColor on macOS) for use in SpriteKit.
    public var skColor: SKColor {
        NSColor(self)
    }
}
#endif
