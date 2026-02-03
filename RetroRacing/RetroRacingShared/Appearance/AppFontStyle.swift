//
//  AppFontStyle.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import SwiftUI

/// User-selectable font style persisted in UserDefaults for consistent typography.
public enum AppFontStyle: String, CaseIterable, Sendable {
    case custom = "custom"
    case system = "system"
    case systemMonospaced = "systemMonospaced"

    public static let storageKey = "selectedFontStyle"
}

extension AppFontStyle {

    /// Returns a SwiftUI `Font` for the given size. Use for labels and body text.
    /// - Parameter size: Point size. Can be scaled by Dynamic Type in the view layer if needed.
    /// - Returns: `.custom("PressStart2P-Regular", size:)`, `.system(size:)`, or `.system(size:, design: .monospaced)`.
    public static func font(for style: AppFontStyle, size: CGFloat) -> Font {
        switch style {
        case .custom:
            return .custom("PressStart2P-Regular", size: size)
        case .system:
            return .system(size: size)
        case .systemMonospaced:
            return .system(size: size, design: .monospaced)
        }
    }
}
