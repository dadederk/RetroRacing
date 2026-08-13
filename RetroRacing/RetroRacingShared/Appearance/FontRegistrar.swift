//
//  FontRegistrar.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation

/// Backward-compatible facade while composition roots migrate to `AppFontRegistry`.
@MainActor
public enum FontRegistrar {
    @available(*, deprecated, message: "Use AppFontRegistry.registerBundledFonts(additionalBundles:)")
    @discardableResult
    public static func registerPressStart2P(additionalBundles: [Bundle] = []) -> Bool {
        AppFontRegistry.registerBundledFonts(additionalBundles: additionalBundles).isAvailable(.custom)
    }
}
