//
//  FontPreferenceStore.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import SwiftUI
import Observation

/// Observable store managing the persisted app font style selection.
@Observable
@MainActor
public final class FontPreferenceStore {
    public var currentStyle: AppFontStyle {
        didSet {
            userDefaults.set(currentStyle.rawValue, forKey: AppFontStyle.storageKey)
        }
    }

    /// When false, hide the Font section in Settings (device doesn't support or failed to load custom font).
    public let isCustomFontAvailable: Bool

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults, customFontAvailable: Bool) {
        self.userDefaults = userDefaults
        self.isCustomFontAvailable = customFontAvailable
        let raw = userDefaults.string(forKey: AppFontStyle.storageKey) ?? AppFontStyle.custom.rawValue
        var style = AppFontStyle(rawValue: raw) ?? .custom
        if !customFontAvailable && style == .custom {
            style = .system
        }
        self.currentStyle = style
    }

    /// Returns a fixed-size SwiftUI font for the current preference.
    /// Use for pixel-locked game UI that should not follow Dynamic Type.
    public func font(fixedSize size: CGFloat) -> Font {
        AppFontStyle.fixedFont(for: currentStyle, size: size)
    }

    /// Returns a semantic SwiftUI font for the current preference.
    /// This follows Dynamic Type for all styles.
    public func font(textStyle: Font.TextStyle) -> Font {
        AppFontStyle.semanticFont(for: currentStyle, textStyle: textStyle)
    }

    /// Backward-compatible alias for fixed-size fonts.
    @available(*, deprecated, renamed: "font(fixedSize:)")
    public func font(size: CGFloat) -> Font {
        font(fixedSize: size)
    }
}
