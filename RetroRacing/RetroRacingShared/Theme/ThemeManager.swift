//
//  ThemeManager.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 03/02/2026.
//

import Foundation
import Observation

/// Manages theme selection and derives availability from the Unlimited Plays entitlement.
@Observable
@MainActor
public final class ThemeManager {
    public private(set) var currentTheme: any GameTheme
    public private(set) var selectedThemeID: ThemeID
    public private(set) var availableThemes: [any GameTheme]
    public var catalogPlatform: ThemeCatalogPlatform { configuration.platform }

    public let releaseFeatures: (any ReleaseFeatureProviding)?

    private var configuration: ThemePlatformConfig
    private let userDefaults: UserDefaults
    private var hasStoredSelection: Bool
    private var hasPremiumAccess: Bool

    nonisolated static let selectedThemeKey = "selectedThemeID"
    private static let obsoleteUnlockedThemesKey = "unlockedThemes"

    public init(
        configuration: ThemePlatformConfig,
        userDefaults: UserDefaults,
        hasPremiumAccess: Bool,
        releaseFeatures: (any ReleaseFeatureProviding)? = nil
    ) {
        let configuration = releaseFeatures?.themeConfiguration ?? configuration
        self.releaseFeatures = releaseFeatures
        self.configuration = configuration
        self.userDefaults = userDefaults
        self.hasPremiumAccess = hasPremiumAccess
        self.availableThemes = configuration.availableThemes

        userDefaults.removeObject(forKey: Self.obsoleteUnlockedThemesKey)
        let storedID = userDefaults.string(forKey: Self.selectedThemeKey).map(ThemeID.init(rawValue:))
        hasStoredSelection = storedID != nil
        let selectedID = storedID.flatMap { candidate in
            Self.isKnown(candidate, configuration: configuration)
                ? candidate
                : nil
        } ?? configuration.defaultThemeID
        self.selectedThemeID = selectedID
        self.currentTheme = Self.resolveTheme(
            preferredID: selectedID,
            configuration: configuration,
            hasPremiumAccess: hasPremiumAccess
        )

        if storedID != nil, storedID != selectedID {
            userDefaults.set(selectedID.rawValue, forKey: Self.selectedThemeKey)
        }
    }

    public func setTheme(_ theme: any GameTheme) {
        guard let theme = availableThemes.first(where: { $0.id == theme.id }),
              isThemeAvailable(theme) else { return }
        hasStoredSelection = true
        selectedThemeID = theme.id
        currentTheme = theme
        userDefaults.set(theme.id.rawValue, forKey: Self.selectedThemeKey)
    }

    public func isThemeAvailable(_ theme: any GameTheme) -> Bool {
        guard let catalogTheme = availableThemes.first(where: { $0.id == theme.id }) else { return false }
        return catalogTheme.isPremium == false || hasPremiumAccess
    }

    public func isThemeAccessible(id: ThemeID) -> Bool {
        guard let theme = availableThemes.first(where: { $0.id == id }) else {
            return false
        }
        return isThemeAvailable(theme)
    }

    /// Replaces the platform catalog, optionally selecting its default theme immediately.
    public func applyConfiguration(
        _ configuration: ThemePlatformConfig,
        selectDefaultTheme: Bool = false
    ) {
        self.configuration = configuration
        availableThemes = configuration.availableThemes

        let preferredID = selectDefaultTheme || !hasStoredSelection
            ? configuration.defaultThemeID : selectedThemeID
        let resolvedSelectedID = Self.isKnown(preferredID, configuration: configuration)
            ? preferredID
            : configuration.defaultThemeID
        selectedThemeID = resolvedSelectedID
        currentTheme = Self.resolveTheme(
            preferredID: resolvedSelectedID,
            configuration: configuration,
            hasPremiumAccess: hasPremiumAccess
        )
        if hasStoredSelection || selectDefaultTheme {
            hasStoredSelection = true
            userDefaults.set(resolvedSelectedID.rawValue, forKey: Self.selectedThemeKey)
        }
    }

    public func refreshReleaseFeatures() {
        guard let releaseFeatures else { return }
        applyConfiguration(releaseFeatures.themeConfiguration)
    }

    private static func isKnown(_ id: ThemeID, configuration: ThemePlatformConfig) -> Bool {
        configuration.availableThemes.contains { $0.id == id }
            || (configuration.platform != .custom && [ThemeID.pocket, .lcd, .eightBit,
                                                     .sixteenBit, .thirtyTwoBit, .sixtyFourBit].contains(id))
    }

    /// Re-resolves the displayed theme without overwriting the user's selection.
    public func syncPremiumAccess(_ hasPremiumAccess: Bool) {
        guard self.hasPremiumAccess != hasPremiumAccess else { return }
        self.hasPremiumAccess = hasPremiumAccess
        currentTheme = Self.resolveTheme(
            preferredID: selectedThemeID,
            configuration: configuration,
            hasPremiumAccess: hasPremiumAccess
        )
    }

    private static func resolveTheme(
        preferredID: ThemeID,
        configuration: ThemePlatformConfig,
        hasPremiumAccess: Bool
    ) -> any GameTheme {
        if let preferred = configuration.availableThemes.first(where: {
            $0.id == preferredID && isTheme($0, availableWith: hasPremiumAccess)
        }) {
            return preferred
        }
        if isTheme(configuration.defaultTheme, availableWith: hasPremiumAccess) {
            return configuration.defaultTheme
        }
        if let firstFreeTheme = configuration.availableThemes.first(where: {
            isTheme($0, availableWith: hasPremiumAccess)
        }) {
            return firstFreeTheme
        }
        return configuration.defaultTheme
    }

    private static func isTheme(
        _ theme: any GameTheme,
        availableWith hasPremiumAccess: Bool
    ) -> Bool {
        theme.isPremium == false || hasPremiumAccess
    }
}
