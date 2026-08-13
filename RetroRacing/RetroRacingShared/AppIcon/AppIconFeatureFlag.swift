//
//  AppIconFeatureFlag.swift
//  RetroRacingShared
//
//  Created by Dani Devesa on 13/08/2026.
//

import Foundation
import Observation

/// Persistence boundary for the alternate-app-icon rollout.
@MainActor
public protocol AppIconFeatureFlagging: AnyObject {
    var isEnabled: Bool { get }

    func refresh()
    func setEnabled(_ isEnabled: Bool)
}

/// Debug-configurable rollout that keeps stored overrides isolated from distribution builds.
@MainActor
@Observable
public final class UserDefaultsAppIconFeatureFlag: AppIconFeatureFlagging {
    public private(set) var isEnabled: Bool

    private let userDefaults: UserDefaults
    private let isConfigurationAllowed: Bool

    public init(
        userDefaults: UserDefaults,
        isConfigurationAllowed: Bool
    ) {
        self.userDefaults = userDefaults
        self.isConfigurationAllowed = isConfigurationAllowed
        isEnabled = DebugGameplayStorageKeys.areAlternateAppIconsEnabled(
            userDefaults: userDefaults,
            debugFeaturesAllowed: isConfigurationAllowed
        )
    }

    public func refresh() {
        isEnabled = DebugGameplayStorageKeys.areAlternateAppIconsEnabled(
            userDefaults: userDefaults,
            debugFeaturesAllowed: isConfigurationAllowed
        )
    }

    public func setEnabled(_ isEnabled: Bool) {
        guard isConfigurationAllowed else {
            self.isEnabled = false
            return
        }

        userDefaults.set(isEnabled, forKey: DebugGameplayStorageKeys.alternateAppIconsEnabled)
        self.isEnabled = isEnabled
    }
}

/// Deterministic rollout used by unsupported platforms, previews, and tests.
@MainActor
public final class FixedAppIconFeatureFlag: AppIconFeatureFlagging {
    public private(set) var isEnabled: Bool
    private let allowsChanges: Bool

    public init(isEnabled: Bool, allowsChanges: Bool = false) {
        self.isEnabled = isEnabled
        self.allowsChanges = allowsChanges
    }

    public func refresh() {}

    public func setEnabled(_ isEnabled: Bool) {
        guard allowsChanges else { return }
        self.isEnabled = isEnabled
    }
}
