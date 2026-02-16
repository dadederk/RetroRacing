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

    /// Returns a fixed-size SwiftUI `Font` for the given point size.
    /// Use this for pixel-locked game elements (HUD/chrome) that should not follow Dynamic Type.
    public static func fixedFont(for style: AppFontStyle, size: CGFloat) -> Font {
        switch style {
        case .custom:
            return .custom("PressStart2P-Regular", size: size)
        case .system:
            return .system(size: size)
        case .systemMonospaced:
            return .system(size: size, design: .monospaced)
        }
    }

    /// Returns a Dynamic-Type-aware semantic SwiftUI `Font`.
    /// - Parameters:
    ///   - style: Selected app font style.
    ///   - textStyle: Semantic text style (`.body`, `.headline`, etc).
    /// - Returns: A semantic system/monospaced font, or a custom font that scales with
    ///   similar growth curves via `Font.custom(_:size:relativeTo:)`.
    public static func semanticFont(for style: AppFontStyle, textStyle: Font.TextStyle) -> Font {
        switch style {
        case .custom:
            return .custom("PressStart2P-Regular", size: defaultCustomPointSize(for: textStyle), relativeTo: textStyle)
        case .system:
            return .system(textStyle, design: .default)
        case .systemMonospaced:
            return .system(textStyle, design: .monospaced)
        }
    }

    static func defaultCustomPointSize(for textStyle: Font.TextStyle) -> CGFloat {
        switch textStyle {
        case .largeTitle:
            return 34
        case .title:
            return 28
        case .title2:
            return 22
        case .title3:
            return 20
        case .headline:
            return 17
        case .subheadline:
            return 15
        case .body:
            return 17
        case .callout:
            return 16
        case .footnote:
            return 13
        case .caption:
            return 12
        case .caption2:
            return 11
        @unknown default:
            return 17
        }
    }
}
