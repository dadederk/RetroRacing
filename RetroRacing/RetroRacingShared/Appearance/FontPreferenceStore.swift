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

    /// Returns a SwiftUI font for the current preference at the given size.
    public func font(size: CGFloat) -> Font {
        AppFontStyle.font(for: currentStyle, size: size)
    }
}
