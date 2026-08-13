//
//  FontPreferenceStore.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import Observation
import SwiftUI

/// Observable store managing the persisted app font style selection.
@Observable
@MainActor
public final class FontPreferenceStore {
    public var currentStyle: AppFontStyle {
        didSet {
            userDefaults.set(currentStyle.rawValue, forKey: AppFontStyle.storageKey)
        }
    }

    public let availability: AppFontAvailability

    public var effectiveStyle: AppFontStyle {
        availability.isAvailable(currentStyle) ? currentStyle : .system
    }

    public var typography: AppTypography {
        AppTypography(selectedStyle: currentStyle, availability: availability)
    }

    /// Compatibility signal retained for callers that only care about Press Start 2P.
    public var isCustomFontAvailable: Bool {
        availability.isAvailable(.custom)
    }

    private let userDefaults: UserDefaults

    public init(userDefaults: UserDefaults, availability: AppFontAvailability) {
        self.userDefaults = userDefaults
        self.availability = availability
        let rawValue = userDefaults.string(forKey: AppFontStyle.storageKey)
            ?? AppFontStyle.custom.rawValue
        currentStyle = AppFontStyle(rawValue: rawValue) ?? .custom
    }

    /// Compatibility initializer for previews and older composition roots.
    public convenience init(userDefaults: UserDefaults, customFontAvailable: Bool) {
        let availableNames: Set<String> = customFontAvailable
            ? Set(AppFontStyle.custom.availableFaces.map(\.postScriptName))
            : []
        self.init(
            userDefaults: userDefaults,
            availability: AppFontAvailability(availablePostScriptNames: availableNames)
        )
    }

    public func isAvailable(_ style: AppFontStyle) -> Bool {
        availability.isAvailable(style)
    }

    /// Compatibility API. New SwiftUI views should use `View.appFont(_:weightTier:)`.
    public func font(textStyle: Font.TextStyle) -> Font {
        AppFontResolver.font(for: textStyle, typography: typography)
    }

    /// Compatibility API for migration only. New views should use semantic or scaled app fonts.
    @available(*, deprecated, message: "Use appFont(_:weightTier:) or appFont(scaledSize:relativeTo:weightTier:)")
    public func font(fixedSize size: CGFloat) -> Font {
        AppFontResolver.font(scaledSize: size, relativeTo: .body, typography: typography)
    }

    @available(*, deprecated, message: "Use appFont(_:weightTier:) or appFont(scaledSize:relativeTo:weightTier:)")
    public func font(size: CGFloat) -> Font {
        font(fixedSize: size)
    }
}
