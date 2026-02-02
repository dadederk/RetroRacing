import Foundation
import SwiftUI

/// Manages current theme, available themes, and premium unlock state.
@Observable
@MainActor
public final class ThemeManager {
    public private(set) var currentTheme: GameTheme
    public private(set) var availableThemes: [GameTheme]
    public private(set) var unlockedThemeIDs: Set<String>

    private let userDefaults: UserDefaults
    private let selectedThemeKey = "selectedThemeID"
    private let unlockedThemesKey = "unlockedThemes"

    public init(initialThemes: [GameTheme], defaultThemeID: String = "lcd", userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        self.availableThemes = initialThemes
        let freeIDs = Set(initialThemes.filter { !$0.isPremium }.map(\.id))
        let storedUnlocked = userDefaults.stringArray(forKey: unlockedThemesKey) ?? []
        self.unlockedThemeIDs = freeIDs.union(storedUnlocked)
        let selectedID = userDefaults.string(forKey: selectedThemeKey) ?? defaultThemeID
        let selected = initialThemes.first { $0.id == selectedID } ?? initialThemes[0]
        self.currentTheme = selected
    }

    public func setTheme(_ theme: GameTheme) {
        guard isThemeAvailable(theme) else { return }
        currentTheme = theme
        userDefaults.set(theme.id, forKey: selectedThemeKey)
    }

    public func isThemeAvailable(_ theme: GameTheme) -> Bool {
        !theme.isPremium || unlockedThemeIDs.contains(theme.id)
    }

    public func unlockTheme(_ theme: GameTheme) {
        var ids = Array(unlockedThemeIDs)
        if !ids.contains(theme.id) {
            ids.append(theme.id)
            unlockedThemeIDs = Set(ids)
            userDefaults.set(ids, forKey: unlockedThemesKey)
        }
    }

    /// Call after successful premium purchase to unlock all premium themes.
    public func unlockPremiumThemes() {
        let premiumIDs = availableThemes.filter(\.isPremium).map(\.id)
        unlockedThemeIDs = unlockedThemeIDs.union(premiumIDs)
        userDefaults.set(Array(unlockedThemeIDs), forKey: unlockedThemesKey)
    }
}
